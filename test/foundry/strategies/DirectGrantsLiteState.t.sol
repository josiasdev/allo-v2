// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {Registry} from "../../../contracts/core/Registry.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";

// Strategy Contracts
import {DirectGrantsLiteStrategy} from "../../../contracts/strategies/direct-grants-lite/DirectGrantsLite.sol";
// State Pattern Contracts
import {LifecycleState} from "../../../contracts/strategies/direct-grants-lite/states/LifecycleState.sol";
// Core libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";

/// @title DirectGrantsLiteStateTest
/// @notice Tests for the State pattern applied to the Direct Grants Lite strategy lifecycle.
contract DirectGrantsLiteStateTest is Test, AlloSetup, RegistrySetupFull, Native, Errors {
    uint64 public registrationStartTime;
    uint64 public registrationEndTime;
    uint256 public poolId;

    DirectGrantsLiteStrategy public strategy;

    Metadata public poolMetadata;

    function setUp() public virtual {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        registrationStartTime = uint64(block.timestamp + 10);
        registrationEndTime = uint64(block.timestamp + 300);

        poolMetadata = Metadata({protocol: 1, pointer: "PoolMetadata"});

        strategy = new DirectGrantsLiteStrategy(address(allo()), "DirectGrantsLiteStrategy");

        vm.prank(allo_owner());
        allo().updatePercentFee(0);

        vm.deal(pool_admin(), 10e18);
        vm.prank(pool_admin());
        poolId = allo().createPoolWithCustomStrategy{value: 1e18}(
            poolProfile_id(),
            address(strategy),
            abi.encode(
                DirectGrantsLiteStrategy.InitializeData({
                    useRegistryAnchor: true,
                    metadataRequired: true,
                    registrationStartTime: registrationStartTime,
                    registrationEndTime: registrationEndTime
                })
            ),
            NATIVE,
            1e18,
            poolMetadata,
            pool_managers()
        );
    }

    /// ============================
    /// ===== State resolution =====
    /// ============================

    function test_currentState_isRegistrationClosed_beforeStart() public {
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationClosed));
    }

    function test_currentState_isRegistrationOpen_atStartBoundary() public {
        vm.warp(registrationStartTime);
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationOpen));
    }

    function test_currentState_isRegistrationOpen_atEndBoundary() public {
        vm.warp(registrationEndTime);
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationOpen));
    }

    function test_currentState_isRegistrationClosed_afterEnd() public {
        vm.warp(uint256(registrationEndTime) + 1);
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationClosed));
    }

    function test_currentState_changes_after_updatePoolTimestamps() public {
        // Pool is closed (before the registration start)
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationClosed));

        // Open the registration for the current timestamp via an update
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(uint64(block.timestamp), uint64(block.timestamp + 100));

        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationOpen));

        // Move forward in time but stay inside the updated window - still open
        vm.warp(block.timestamp + 50);
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationOpen));

        // Close the registration by moving the window entirely to the past
        vm.prank(pool_admin());
        strategy.updatePoolTimestamps(1, 10);

        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationClosed));
    }

    function test_isPoolActive_consistentWith_currentState() public {
        assertFalse(strategy.isPoolActive());

        vm.warp(registrationStartTime);
        assertTrue(strategy.isPoolActive());
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationOpen));

        vm.warp(uint256(registrationEndTime) + 1);
        assertFalse(strategy.isPoolActive());
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationClosed));
    }

    function test_stateContract_getters() public {
        assertEq(uint8(strategy.registrationOpenState().state()), uint8(LifecycleState.PoolState.RegistrationOpen));
        assertEq(uint8(strategy.registrationClosedState().state()), uint8(LifecycleState.PoolState.RegistrationClosed));
        assertTrue(strategy.registrationOpenState().isPoolActive());
        assertFalse(strategy.registrationClosedState().isPoolActive());
    }

    /// ============================
    /// ====== Registration ========
    /// ============================

    function test_registerRecipient_succeeds_whenRegistrationOpen() public {
        vm.warp(registrationStartTime + 10);
        __isOwnerOrMemberOfProfileTrue();

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        address recipientId = strategy.registerRecipient(data, profile1_member1());

        assertEq(recipientId, profile1_anchor());
        assertEq(uint8(strategy.getRecipientStatus(recipientId)), uint8(IStrategy.Status.Pending));
    }

    function test_registerRecipient_reverts_REGISTRATION_NOT_ACTIVE_beforeStart() public {
        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        strategy.registerRecipient(data, profile1_member1());
    }

    function test_registerRecipient_reverts_REGISTRATION_NOT_ACTIVE_afterEnd() public {
        vm.warp(uint256(registrationEndTime) + 1);

        vm.expectRevert(REGISTRATION_NOT_ACTIVE.selector);

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        strategy.registerRecipient(data, profile1_member1());
    }

    /// ============================
    /// ======== Allocation ========
    /// ============================

    function test_allocate_succeeds_whenRegistrationOpen() public {
        address recipientId = __register_accept_recipient();

        DirectGrantsLiteStrategy.Allocation[] memory allocations = new DirectGrantsLiteStrategy.Allocation[](1);
        allocations[0] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId, amount: 1e17});

        vm.prank(pool_admin());
        allo().allocate{value: 1e17}(poolId, abi.encode(allocations));
    }

    function test_allocate_succeeds_whenRegistrationClosed() public {
        // Register and accept a recipient while the registration is open
        address recipientId = __register_accept_recipient();

        // Move past the registration end - the pool is now in 'RegistrationClosed'
        vm.warp(uint256(registrationEndTime) + 1);
        assertEq(uint8(strategy.currentState()), uint8(LifecycleState.PoolState.RegistrationClosed));

        // Allocation remains allowed in the closed state (legacy behavior)
        DirectGrantsLiteStrategy.Allocation[] memory allocations = new DirectGrantsLiteStrategy.Allocation[](1);
        allocations[0] = DirectGrantsLiteStrategy.Allocation({token: NATIVE, recipientId: recipientId, amount: 1e17});

        vm.prank(pool_admin());
        allo().allocate{value: 1e17}(poolId, abi.encode(allocations));
    }

    /// ============================
    /// ====== Distribution ========
    /// ============================

    function test_distribute_reverts_NOT_IMPLEMENTED_whenRegistrationOpen() public {
        vm.warp(registrationStartTime + 10);

        vm.expectRevert(NOT_IMPLEMENTED.selector);

        vm.prank(pool_admin());
        allo().distribute(poolId, new address[](0), bytes(""));
    }

    function test_distribute_reverts_NOT_IMPLEMENTED_whenRegistrationClosed() public {
        vm.warp(uint256(registrationEndTime) + 1);

        vm.expectRevert(NOT_IMPLEMENTED.selector);

        vm.prank(pool_admin());
        allo().distribute(poolId, new address[](0), bytes(""));
    }

    /// ====================
    /// ===== Helpers ======
    /// ====================

    function __generateRecipientWithId(address _recipientId) internal pure returns (bytes memory) {
        Metadata memory metadata = Metadata({protocol: 1, pointer: "metadata"});

        return abi.encode(_recipientId, recipientAddress(), metadata);
    }

    function __isOwnerOrMemberOfProfileTrue() internal {
        vm.mockCall(
            address(registry()), abi.encodeWithSelector(Registry.isOwnerOrMemberOfProfile.selector), abi.encode(true)
        );
    }

    function __register_recipient() internal returns (address recipientId) {
        vm.warp(registrationStartTime + 10);

        __isOwnerOrMemberOfProfileTrue();

        vm.prank(address(allo()));
        bytes memory data = __generateRecipientWithId(profile1_anchor());
        recipientId = strategy.registerRecipient(data, profile1_member1());
    }

    function __register_accept_recipient() internal returns (address recipientId) {
        recipientId = __register_recipient();
        uint256 refRecipientsCounter = strategy.recipientsCounter();

        DirectGrantsLiteStrategy.ApplicationStatus[] memory statuses =
            new DirectGrantsLiteStrategy.ApplicationStatus[](1);
        statuses[0] = DirectGrantsLiteStrategy.ApplicationStatus({
            index: 0, statusRow: __buildStatusRow(0, uint8(IStrategy.Status.Accepted))
        });

        vm.prank(pool_admin());
        strategy.reviewRecipients(statuses, refRecipientsCounter);
    }

    function __buildStatusRow(uint256 _recipientIndex, uint256 _status) internal pure returns (uint256 statusRow) {
        uint256 colIndex = (_recipientIndex % 64) * 4;

        uint256 newRow = 0 & ~(15 << colIndex);
        statusRow = newRow | (_status << colIndex);
    }

    function profile1_anchor() public pure override returns (address) {
        return 0xad5FDFa74961f0b6F1745eF0A1Fa0e115caa9641;
    }

    function recipientAddress() public pure override returns (address) {
        return 0x7b6d3eB9bb22D0B13a2FAd6D6bDBDc34Ad2c5849;
    }
}
