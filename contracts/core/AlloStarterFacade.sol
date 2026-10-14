// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// Importing the necessary interfaces and structs from the Allo Protocol
import "./interfaces/IRegistry.sol";
import "./interfaces/IAllo.sol";
import "./libraries/Metadata.sol";

contract AlloStarterFacade {
    IRegistry public registry;
    IAllo public allo;

    // Constructor to inject the addresses of the main contracts
    constructor(address _registry, address _allo) {
        registry = IRegistry(_registry);
        allo = IAllo(_allo);
    }

    function initializeCampaign(
        uint256 _nonce,
        string memory _name,
        Metadata memory _metadata,
        address _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        address[] memory _managers
    ) external returns (uint256 poolId) {

       // The Facade orchestrates the complexity of the subsystem internally.
        bytes32 profileId = registry.createProfile(
            _nonce, _name, _metadata, msg.sender, _managers
        );

        return allo.createPool(
            profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );
    }
}