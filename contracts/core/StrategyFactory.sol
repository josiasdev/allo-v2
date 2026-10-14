// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// Interfaces
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IStrategyFactory} from "./interfaces/IStrategyFactory.sol";
// Internal Libraries
import {Clone} from "./libraries/Clone.sol";

/// @title StrategyFactory
/// @notice Concrete Factory that instantiates strategy contracts by creating deterministic clones.
/// @dev This is the Concrete Factory of the Factory Method design pattern (GoF Creational).
///      The cloning logic ('Clone.createClone') previously lived in the Allo contract and is now
///      encapsulated here, keeping the Allo contract focused on pool orchestration. The nonce is
///      tracked per caller so every CREATE2 salt derived from '(msg.sender, nonce)' is unique,
///      preventing clone deployment collisions.
contract StrategyFactory is IStrategyFactory {
    /// @notice Maps the caller address to a nonce used to derive a unique clone salt
    /// @dev 'msg.sender' -> 'nonce' for cloning strategies
    mapping(address => uint256) private _nonces;

    /// @notice Creates a deterministic clone of the given strategy implementation
    /// @param _implementation The address of the cloneable strategy implementation
    /// @return strategy The newly created strategy instance
    function createStrategyClone(address _implementation) external returns (IStrategy) {
        return IStrategy(Clone.createClone(_implementation, _nonces[msg.sender]++));
    }
}
