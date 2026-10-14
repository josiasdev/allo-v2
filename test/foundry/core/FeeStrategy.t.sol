// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IFeeStrategy} from "../../../contracts/core/interfaces/IFeeStrategy.sol";
// Core contracts
import {FlatFeeStrategy} from "../../../contracts/core/fees/FlatFeeStrategy.sol";
// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {MockStrategy} from "../../utils/MockStrategy.sol";
import {MockERC20} from "../../utils/MockERC20.sol";
import {MockFeeStrategy} from "../../utils/MockFeeStrategy.sol";

contract FeeStrategyTest is Test, AlloSetup, RegistrySetupFull, Native, Errors {
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);
    event FeeStrategyUpdated(address feeStrategy);

    address public strategy;
    MockERC20 public token;

    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public metadata = Metadata({protocol: 1, pointer: "strategy pointer"});

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        token = new MockERC20();
        token.mint(local(), mintAmount);
        token.mint(pool_admin(), mintAmount);
        token.approve(address(allo()), mintAmount);

        vm.prank(pool_admin());
        token.approve(address(allo()), mintAmount);

        strategy = address(new MockStrategy(address(allo())));

        vm.startPrank(allo_owner());
        allo().transferOwnership(local());
        vm.stopPrank();
    }

    function _utilCreatePool(uint256 _amount) internal returns (uint256) {
        vm.prank(pool_admin());
        return allo()
            .createPoolWithCustomStrategy(
                poolProfile_id(), strategy, "0x", address(token), _amount, metadata, pool_managers()
            );
    }

    // ====================================
    // ===== FlatFeeStrategy unit tests ===
    // ====================================

    function test_FlatFeeStrategy_calculateFee() public {
        FlatFeeStrategy feeStrategy = new FlatFeeStrategy(1e16); // 1%

        assertEq(feeStrategy.percentFee(), 1e16);
        assertEq(feeStrategy.calculateFee(0), 0);
        assertEq(feeStrategy.calculateFee(1e20), 1e18); // 1% of 1e20
        assertEq(feeStrategy.calculateFee(1e18), 1e16); // 1% of 1e18
    }

    function test_FlatFeeStrategy_calculateFee_10Percent() public {
        FlatFeeStrategy feeStrategy = new FlatFeeStrategy(1e17); // 10%

        assertEq(feeStrategy.calculateFee(1e20), 1e19);
    }

    function test_FlatFeeStrategy_calculateFee_100Percent() public {
        FlatFeeStrategy feeStrategy = new FlatFeeStrategy(1e18); // 100%

        assertEq(feeStrategy.calculateFee(1e20), 1e20);
    }

    function testRevert_FlatFeeStrategy_constructor_INVALID_FEE() public {
        vm.expectRevert(INVALID_FEE.selector);
        new FlatFeeStrategy(2 * 1e18);
    }

    // ====================================
    // ====== Dependency injection ========
    // ====================================

    function test_initialize_injectsDefaultFeeStrategy() public {
        IFeeStrategy feeStrategy = allo().getFeeStrategy();

        assertTrue(address(feeStrategy) != address(0));
        // The default strategy reproduces the legacy percentFee math (1% of 1e20 = 1e18)
        assertEq(feeStrategy.calculateFee(1e20), 1e18);
    }

    function test_updatePercentFee_syncsDefaultFeeStrategy() public {
        allo().updatePercentFee(0);

        // The default strategy must now charge no fee
        assertEq(allo().getFeeStrategy().calculateFee(1e20), 0);

        allo().updatePercentFee(1e17); // 10%

        assertEq(allo().getFeeStrategy().calculateFee(1e20), 1e19);
    }

    // ====================================
    // ======== Fee delegation ===========
    // ====================================

    function test_fundPool_delegatesFeeCalculationToStrategy() public {
        uint256 poolId = _utilCreatePool(0);

        // Same expectations as the legacy 'test_fundPool': 1% fee on 1e20
        vm.expectEmit(true, false, false, true);
        emit PoolFunded(poolId, 9.9e19, 1e18);

        allo().fundPool(poolId, 10 * 10e18);
    }

    function test_updateFeeStrategy_swapsFeeAlgorithm() public {
        uint256 poolId = _utilCreatePool(0);

        // Swap the algorithm for a fixed 5 ether fee, fully decoupled from 'percentFee'
        MockFeeStrategy customFeeStrategy = new MockFeeStrategy(5 ether);

        vm.expectEmit(true, false, false, true);
        emit FeeStrategyUpdated(address(customFeeStrategy));
        allo().updateFeeStrategy(address(customFeeStrategy));

        assertEq(address(allo().getFeeStrategy()), address(customFeeStrategy));

        // The pool is funded charging the custom fixed fee instead of the percent fee
        vm.expectEmit(true, false, false, true);
        emit PoolFunded(poolId, 10 * 10e18 - 5 ether, 5 ether);

        allo().fundPool(poolId, 10 * 10e18);
    }

    function test_updateFeeStrategy_customStrategyCanChargeZero() public {
        uint256 poolId = _utilCreatePool(0);

        allo().updateFeeStrategy(address(new MockFeeStrategy(0)));

        vm.expectEmit(true, false, false, true);
        emit PoolFunded(poolId, 10 * 10e18, 0);

        allo().fundPool(poolId, 10 * 10e18);
    }

    // ====================================
    // ======== Access control ===========
    // ====================================

    function testRevert_updateFeeStrategy_UNAUTHORIZED() public {
        MockFeeStrategy feeStrategy = new MockFeeStrategy(0);

        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo().updateFeeStrategy(address(feeStrategy));
    }

    function testRevert_updateFeeStrategy_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        allo().updateFeeStrategy(address(0));
    }
}
