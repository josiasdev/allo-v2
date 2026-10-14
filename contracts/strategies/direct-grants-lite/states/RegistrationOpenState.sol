// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Core Contracts
import {LifecycleState} from "./LifecycleState.sol";
// Internal Libraries
import {Errors} from "../../../core/libraries/Errors.sol";

/// @title RegistrationOpenState
/// @notice Concrete State entered while the pool is inside its registration window.
/// @dev While this state is active: recipients may register, pool managers may allocate funds to
///      accepted recipients, and distribution is not implemented (mirrors the legacy behavior).
contract RegistrationOpenState is LifecycleState, Errors {
    /// @notice Returns 'PoolState.RegistrationOpen'
    /// @return The 'PoolState' enum value
    function state() public pure override returns (LifecycleState.PoolState) {
        return LifecycleState.PoolState.RegistrationOpen;
    }

    /// @notice Registration is allowed while this state is active
    function checkRegistration() external pure override {}

    /// @notice Allocation is allowed while this state is active
    function checkAllocation() external pure override {}

    /// @notice Distribution is not implemented in this strategy and always reverts
    function checkDistribution() external pure override {
        revert NOT_IMPLEMENTED();
    }

    /// @notice The pool is active while the registration window is open
    /// @return 'true' always for this state
    function isPoolActive() external pure override returns (bool) {
        return true;
    }
}
