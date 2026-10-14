// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Core Contracts
import {LifecycleState} from "./LifecycleState.sol";
// Internal Libraries
import {Errors} from "../../../core/libraries/Errors.sol";

/// @title RegistrationClosedState
/// @notice Concrete State entered while the pool is outside its registration window.
/// @dev While this state is active: recipients may not register (reverts with 'REGISTRATION_NOT_ACTIVE'),
///      pool managers may still allocate funds to accepted recipients, and distribution is not
///      implemented (mirrors the legacy behavior).
contract RegistrationClosedState is LifecycleState, Errors {
    /// @notice Returns 'PoolState.RegistrationClosed'
    /// @return The 'PoolState' enum value
    function state() public pure override returns (LifecycleState.PoolState) {
        return LifecycleState.PoolState.RegistrationClosed;
    }

    /// @notice Registration is not allowed while this state is active and reverts
    function checkRegistration() external pure override {
        revert REGISTRATION_NOT_ACTIVE();
    }

    /// @notice Allocation is allowed while this state is active
    function checkAllocation() external pure override {}

    /// @notice Distribution is not implemented in this strategy and always reverts
    function checkDistribution() external pure override {
        revert NOT_IMPLEMENTED();
    }

    /// @notice The pool is not active while the registration window is closed
    /// @return 'false' always for this state
    function isPoolActive() external pure override returns (bool) {
        return false;
    }
}
