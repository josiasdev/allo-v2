# AlloStarterFacade.sol

The `AlloStarterFacade` contract serves as a simplified entry point to the Allo Protocol. It abstracts the complexity of interacting with multiple core contracts by consolidating profile creation and pool initialization into a single transaction.

## Table of Contents

- [AlloStarterFacade.sol](#allostarterfacadesol)
- [Sequence Diagrams](#sequence-diagrams) 
  - [Initialize Campaign](#initialize-campaign) 
- [Smart Contract Overview](#smart-contract-overview) 
  - [Storage Variables](#storage-variables) 
  - [Functions](#functions) 
- [User Flows](#user-flows)

## Sequence Diagrams

### Initialize Campaign

sequenceDiagram

    participant Client as Client/dApp

    participant Facade as AlloStarterFacade

    participant Registry as Registry

    participant Allo as Allo Contract

    Client->>Facade: initializeCampaign(...)

    Facade->>Registry: createProfile(...)

    Registry-->>Facade: returns profileId

    Facade->>Allo: createPool(profileId, ...)

    Allo-->>Facade: returns poolId

    Facade-->>Client: Returns poolId

## Smart Contract Overview

- **Purpose:** To reduce coupling between external clients and the Allo Protocol's internal subsystems (Registry and Allo).
- **Solidity Version:** 0.8.19 
- **Pattern:** Facade (GoF Structural Pattern)

### Storage Variables

1. `registry` (IRegistry): An interface to the Allo Protocol's Registry contract used for profile management.
2. `allo` (IAllo): An interface to the Allo Protocol's core contract used to create and manage pools.

### Functions

1. **initializeCampaign** (`initializeCampaign`): This function acts as the single point of interaction for a user or dApp wanting to start a funding campaign. It takes all necessary parameters for both profile creation and pool creation, executing them sequentially in one transaction.

## User Flows

### Campaign Initialization

* A user (or frontend client) wants to create a new funding pool but doesn't have a Registry profile yet. 
* Instead of sending two separate transactions, the user calls `initializeCampaign` on the `AlloStarterFacade`. 
* The function requires parameters for the profile (nonce, name, metadata, managers) and parameters for the pool (strategy, initStrategyData, token, amount).
* The Facade internally calls `Registry.createProfile()` and captures the returned `profileId`. 
* The Facade then immediately calls `Allo.createPool()` using the newly generated `profileId`. 
* The `poolId` is returned to the user, completing the setup efficiently and saving gas.
