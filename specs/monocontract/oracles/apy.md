# Specification Document - ApyOracle Contract

## Business Logic

The `ApyOracle` contract serves as a data feed for tracking and updating the Annual Percentage Yield (APY) and other related data for validators on a blockchain network. The purpose of this contract is to provide a mechanism for maintaining and updating APY-related information for validators, making it accessible to other contracts or external systems on the blockchain.

### Data Feed

The contract maintains a list of validator nodes and their associated APY data. Each validator node is identified by its unique Ethereum address. The APY data includes:

- `account`: The Ethereum address of the validator node.
- `rank`: An integer representing the rank or position of the validator.
- `apy`: A percentage value (up to two decimal places) representing the Annual Percentage Yield.
- `fromBlock`: The starting block number for which the APY data is applicable.
- `toBlock`: The ending block number for which the APY data is applicable.
- `pbftCount`: The count of PBFT consensus events associated with the validator node.

The data feed can be updated by a designated "data feed" address, ensuring that only authorized contracts or accounts can modify the APY data.

## Data Structure Definitions

### `NodeData` Struct

- `account` (address): The Ethereum address of the validator node.
- `rank` (uint16): The rank or position of the validator node.
- `apy` (uint16): The Annual Percentage Yield offered by the validator node.
- `fromBlock` (uint64): The starting block number for which the APY data is applicable.
- `toBlock` (uint64): The ending block number for which the APY data is applicable.
- `pbftCount` (uint256): The count of PBFT consensus events associated with the validator node.

## Implemented Methods

### `constructor`

- **Description**: The constructor initializes the contract with the address of the data feed, which is responsible for updating the APY data.

- **Input Parameters**:
  - `dataFeed` (address): The Ethereum address of the data feed responsible for updating APY data.

### `getDataFeedAddress`

- **Description**: This function allows external contracts or accounts to query the address of the data feed.

- **Returns**:
  - `address`: The Ethereum address of the data feed.

### `getNodeData`

- **Description**: Retrieves the APY data associated with a specific validator node.

- **Input Parameters**:

  - `node` (address): The Ethereum address of the validator node.

- **Returns**:
  - `NodeData` (struct): The APY data for the specified validator node.

### `updateNodeData`

- **Description**: Allows the data feed to update the APY data for a specific validator node.

- **Input Parameters**:

  - `node` (address): The Ethereum address of the validator node.
  - `data` (NodeData): The updated APY data for the validator node.

- **Modifiers**:

  - `OnlyDataFeed`: Ensures that only the designated data feed address can call this function.

- **Requirements**:

  - The `fromBlock` value in the updated data must be greater than the previous `fromBlock`.
  - The `fromBlock` value must be less than the `toBlock` value.

- **Events**:
  - `NodeDataUpdated`: Emits an event to indicate that the APY data for a validator node has been updated.

## Event

### `NodeDataUpdated` Event

- **Description**: This event is emitted when the APY data for a validator node is updated.

- **Parameters**:
  - `node` (indexed address): The Ethereum address of the validator node.
  - `apy` (uint16): The updated Annual Percentage Yield (APY) for the validator node.
  - `pbftCount` (uint256): The updated count of PBFT consensus events for the validator node.

---

This specification document outlines the purpose, data structure definitions, and methods implemented in the `ApyOracle` contract. It serves as a reference for understanding the functionality and usage of the contract on the blockchain.
