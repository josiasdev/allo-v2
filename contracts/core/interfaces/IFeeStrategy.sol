// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// @title IFeeStrategy Interface
/// @notice Defines the contract for calculating the protocol fee charged when a pool is funded.
/// @dev This is the Strategy interface of the Strategy design pattern (GoF Behavioral).
///      It allows the fee calculation algorithm to vary independently from the Allo contract,
///      which only depends on this abstraction instead of a hardcoded formula.
interface IFeeStrategy {
    /// @notice Calculates the fee to charge for a given amount
    /// @param _amount The amount to calculate the fee on
    /// @return fee The fee amount to charge
    function calculateFee(uint256 _amount) external view returns (uint256);
}
