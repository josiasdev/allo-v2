// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Core contracts
import {StrategyFactory} from "../../../contracts/core/StrategyFactory.sol";
// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {MockStrategy} from "../../utils/MockStrategy.sol";
import {MockStrategyFactory} from "../../utils/MockStrategyFactory.sol";
import {TestStrategy} from "../../utils/TestStrategy.sol";

contract StrategyFactoryTest is Test, AlloSetup, RegistrySetupFull, Native, Errors {
    event StrategyFactoryUpdated(address strategyFactory);

    address public strategy;

    Metadata public metadata = Metadata({protocol: 1, pointer: "strategy pointer"});

    function setUp() public {
        __RegistrySetupFull();
        __AlloSetup(address(registry()));

        strategy = address(new MockStrategy(address(allo())));

        vm.startPrank(allo_owner());
        allo().transferOwnership(local());
        vm.stopPrank();
    }

    // ====================================
    // ===== StrategyFactory unit ========
    // ====================================

    function test_createStrategyClone_returnsNewInstance() public {
        StrategyFactory factory = new StrategyFactory();

        address clone = address(factory.createStrategyClone(strategy));

        assertTrue(clone != strategy);
        assertTrue(clone.code.length > 0);
    }

    function test_createStrategyClone_uniqueClones() public {
        StrategyFactory factory = new StrategyFactory();

        address clone1 = address(factory.createStrategyClone(strategy));
        address clone2 = address(factory.createStrategyClone(strategy));

        assertTrue(clone1 != clone2);
    }

    // ====================================
    // ====== Dependency injection ========
    // ====================================

    function test_initialize_injectsStrategyFactory() public {
        assertTrue(address(allo().getStrategyFactory()) != address(0));
    }

    function test_createPool_clonesViaFactory() public {
        allo().addToCloneableStrategies(strategy);

        vm.prank(pool_admin());
        uint256 poolId = allo().createPool(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers());

        address poolStrategy = address(allo().getPool(poolId).strategy);

        // The pool strategy is a fresh instance created by the factory, not the implementation itself
        assertTrue(poolStrategy != strategy);
        assertTrue(poolStrategy.code.length > 0);
    }

    // ====================================
    // ======== Factory swapping =========
    // ====================================

    function test_updateStrategyFactory_customFactory() public {
        // Pre-configure a preset strategy the mock factory will hand out (no cloning involved)
        TestStrategy presetStrategy = new TestStrategy(address(allo()), "PresetStrategy");
        presetStrategy.setPoolId(1);

        MockStrategyFactory customFactory = new MockStrategyFactory();
        customFactory.setResult(address(presetStrategy));

        vm.expectEmit(true, false, false, true);
        emit StrategyFactoryUpdated(address(customFactory));
        allo().updateStrategyFactory(address(customFactory));

        assertEq(address(allo().getStrategyFactory()), address(customFactory));

        // The Allo contract must consume whatever the injected factory returns
        allo().addToCloneableStrategies(strategy);

        vm.prank(pool_admin());
        uint256 poolId = allo().createPool(poolProfile_id(), strategy, "0x", NATIVE, 0, metadata, pool_managers());

        assertEq(address(allo().getPool(poolId).strategy), address(presetStrategy));
    }

    // ====================================
    // ======== Access control ===========
    // ====================================

    function testRevert_updateStrategyFactory_UNAUTHORIZED() public {
        MockStrategyFactory customFactory = new MockStrategyFactory();

        vm.expectRevert();

        vm.prank(makeAddr("anon"));
        allo().updateStrategyFactory(address(customFactory));
    }

    function testRevert_updateStrategyFactory_ZERO_ADDRESS() public {
        vm.expectRevert(ZERO_ADDRESS.selector);
        allo().updateStrategyFactory(address(0));
    }
}
