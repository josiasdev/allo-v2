// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Interfaces
import {IStrategy} from "./IStrategy.sol";

/// @title IStrategyFactory Interface
/// @notice Defines the contract for instantiating strategy contracts used by pool creation.
/// @dev This is the Factory interface of the Factory Method design pattern (GoF Creational).
///      It allows the instantiation algorithm (e.g. cloning) to vary independently from the
///      Allo contract, which only depends on this abstraction instead of creating clones itself.
interface IStrategyFactory {
    /// @notice Creates a new strategy instance from a cloneable strategy implementation
    /// @param _implementation The address of the cloneable strategy implementation
    /// @return strategy The newly created strategy instance
    function createStrategyClone(address _implementation) external returns (IStrategy);
}
