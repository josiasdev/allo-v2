// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import {IStrategy} from "../../contracts/core/interfaces/IStrategy.sol";
import {IStrategyFactory} from "../../contracts/core/interfaces/IStrategyFactory.sol";

/// @title MockStrategyFactory
/// @notice Mock strategy factory that returns a preset address instead of creating a clone.
/// @dev Used in tests to prove that the Allo contract delegates strategy instantiation to the
///      injected 'IStrategyFactory' instead of cloning implementations by itself.
contract MockStrategyFactory is IStrategyFactory {
    /// @notice The address returned by 'createStrategyClone()'
    address public result;

    /// @notice Updates the address returned by 'createStrategyClone()'
    /// @param _result The address to return
    function setResult(address _result) external {
        result = _result;
    }

    /// @notice Returns the preset address, ignoring the implementation passed
    /// @dev The '_implementation' parameter is intentionally unused to prove the Allo contract
    ///      consumes whatever this factory returns
    /// @return The preset strategy address
    function createStrategyClone(address) external view returns (IStrategy) {
        return IStrategy(result);
    }
}
