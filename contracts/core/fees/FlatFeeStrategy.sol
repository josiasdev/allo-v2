// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IFeeStrategy} from "../interfaces/IFeeStrategy.sol";
// Internal Libraries
import {Errors} from "../libraries/Errors.sol";

/// @title FlatFeeStrategy
/// @notice Concrete Strategy that applies a constant (flat) percentage fee on the amount being funded.
/// @dev This strategy preserves the legacy fee behavior of the Allo contract, where the fee is
///      calculated as '(_amount * percentFee) / 1e18'. It is the default strategy injected into
///      the Allo contract, which now delegates fee calculation to an 'IFeeStrategy' instead of
///      computing it inline. 1e18 represents 100%, 1e17 represents 10% and so on.
contract FlatFeeStrategy is IFeeStrategy, Errors {
    /// @notice The fee denominator (1e18) which represents 100%
    uint256 public constant FEE_DENOMINATOR = 1e18;

    /// @notice The flat percentage fee applied to every funding operation
    /// @dev 1e18 = 100%, 1e17 = 10%, 1e16 = 1%, 1e15 = 0.1%
    uint256 public percentFee;

    /// @notice Sets the flat percentage fee of the strategy
    /// @param _percentFee The percentage fee (1e18 = 100%)
    constructor(uint256 _percentFee) {
        if (_percentFee > FEE_DENOMINATOR) revert INVALID_FEE();

        percentFee = _percentFee;
    }

    /// @notice Calculates the fee for a given amount using the flat percentage fee
    /// @param _amount The amount to calculate the fee on
    /// @return fee The fee amount to charge
    function calculateFee(uint256 _amount) external view returns (uint256) {
        return (_amount * percentFee) / FEE_DENOMINATOR;
    }
}
