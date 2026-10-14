// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {IFeeStrategy} from "../../contracts/core/interfaces/IFeeStrategy.sol";

/// @title MockFeeStrategy
/// @notice Mock fee strategy that always returns a fixed fee amount regardless of the input.
/// @dev Used in tests to prove that the Allo contract delegates fee calculation to the
///      injected 'IFeeStrategy' instead of computing it from its own 'percentFee'.
contract MockFeeStrategy is IFeeStrategy {
    /// @notice The fixed fee amount returned by 'calculateFee()'
    uint256 public fixedFee;

    /// @notice Sets the fixed fee amount
    /// @param _fixedFee The fixed fee amount
    constructor(uint256 _fixedFee) {
        fixedFee = _fixedFee;
    }

    /// @notice Updates the fixed fee amount
    /// @param _fixedFee The new fixed fee amount
    function setFixedFee(uint256 _fixedFee) external {
        fixedFee = _fixedFee;
    }

    /// @notice Returns the fixed fee amount, ignoring the amount passed
    /// @dev The '_amount' parameter is intentionally unused to keep the fee constant
    /// @return fee The fixed fee amount
    function calculateFee(uint256) external view returns (uint256) {
        return fixedFee;
    }
}
