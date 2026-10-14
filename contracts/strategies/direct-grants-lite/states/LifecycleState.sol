// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title LifecycleState
/// @notice Abstract State contract of the State pattern for the Direct Grants Lite strategy lifecycle.
/// @dev Each concrete state encapsulates which actions are permitted while that state is active.
///      The strategy (Context) resolves the current state from its registration timestamps and
///      delegates the lifecycle validation to it, instead of branching inline with 'if' statements.
abstract contract LifecycleState {
    /// ================================
    /// ========== Enum ================
    /// ================================
    /// @notice The lifecycle states a Direct Grants Lite pool can be in.
    /// @dev 'RegistrationOpen' - the current time is within the registration window.
    ///      'RegistrationClosed' - the current time is outside the registration window.
    enum PoolState {
        RegistrationOpen,
        RegistrationClosed
    }

    /// ===============================
    /// =========== Methods ===========
    /// ===============================

    /// @notice Returns the 'PoolState' this state object represents.
    /// @return The 'PoolState' enum value
    function state() public view virtual returns (PoolState);

    /// @notice Validates that registering a recipient is allowed in this state.
    /// @dev Reverts if registration is not permitted while in this state.
    function checkRegistration() external view virtual;

    /// @notice Validates that allocating funds is allowed in this state.
    /// @dev Reverts if allocation is not permitted while in this state.
    function checkAllocation() external view virtual;

    /// @notice Validates that distributing funds is allowed in this state.
    /// @dev Reverts if distribution is not permitted while in this state.
    function checkDistribution() external view virtual;

    /// @notice Whether the pool is considered active while in this state.
    /// @return 'true' if the pool is active in this state, otherwise 'false'
    function isPoolActive() external view virtual returns (bool);
}
