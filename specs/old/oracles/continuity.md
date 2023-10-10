# Specification Document - NodeContinuityOracle Contract

## Business Logic

The `NodeContinuityOracle` contract serves as a data feed for tracking and updating continuity-related statistics for nodes on a blockchain network. The purpose of this contract is to provide a mechanism for maintaining and updating statistics related to node continuity, including DAG (Directed Acyclic Graph) counts, timestamps, PBFT (Practical Byzantine Fault Tolerance) events, and transaction counts. These statistics can be crucial for assessing the performance and reliability of nodes on the network.

### Data Feed

The contract maintains a list of node statistics, where each node is identified by its unique Ethereum address. The node statistics include:

- `dagsCount` (uint64): The count of DAGs produced by the node.
- `lastDagTimestamp` (uint64): The timestamp of the last DAG produced by the node.
- `lastPbftTimestamp` (uint64): The timestamp of the last PBFT event involving the node.
- `lastTransactionTimestamp` (uint64): The timestamp of the last transaction involving the node.
- `pbftCount` (uint64): The count of PBFT consensus events involving the node.
- `transactionsCount` (uint64): The count of transactions involving the node.

The data feed can be updated by a designated "data feed" address, ensuring that only authorized contracts or accounts can modify the node statistics.

## Data Structure Definitions

### `NodeStats` Struct

- `dagsCount` (uint64): The count of DAGs produced by the node.
- `lastDagTimestamp` (uint64): The timestamp of the last DAG produced by the node.
- `lastPbftTimestamp` (uint64): The timestamp of the last PBFT event involving the node.
- `lastTransactionTimestamp` (uint64): The timestamp of the last transaction involving the node.
- `pbftCount` (uint64): The count of PBFT consensus events involving the node.
- `transactionsCount` (uint64): The count of transactions involving the node.

## Implemented Methods

### `constructor`

- **Description**: The constructor initializes the contract with the address of the data feed, which is responsible for updating the node statistics.

- **Input Parameters**:
  - `dataFeed` (address): The Ethereum address of the data feed responsible for updating node statistics.

### `getDataFeedAddress`

- **Description**: This function allows external contracts or accounts to query the address of the data feed.

- **Returns**:
  - `address`: The Ethereum address of the data feed.

### `updateNodeStats`

- **Description**: Allows the data feed to update the node statistics for a specific node.

- **Input Parameters**:

  - `node` (address): The Ethereum address of the node for which statistics are being updated.
  - `timestamp` (uint64): The timestamp for which the statistics apply.
  - `data` (NodeStats): The updated statistics for the node.

- **Modifiers**:

  - `OnlyDataFeed`: Ensures that only the designated data feed address can call this function.

- **Requirements**:

  - The `timestamp` provided must not already exist in the node statistics.
  - The data must be associated with a valid Ethereum node address.

- **Events**:
  - `NodeDataUpdated`: Emits an event to indicate that the node statistics have been updated.

### `getNodeUpdateTimestamps`

- **Description**: Retrieves the timestamps for which statistics have been updated for a specific node.

- **Input Parameters**:

  - `node` (address): The Ethereum address of the node.

- **Returns**:
  - `timestamps` (uint64[]): An array of timestamps for which statistics have been updated for the node.

### `getNodeStatsFrom`

- **Description**: Retrieves the node statistics for a specific timestamp.

- **Input Parameters**:

  - `timestamp` (uint64): The timestamp for which node statistics are requested.

- **Returns**:
  - `NodeStats` (struct): The node statistics for the specified timestamp.

## Event

### `NodeDataUpdated` Event

- **Description**: This event is emitted when the node statistics for a specific node and timestamp are updated.

- **Parameters**:
  - `node` (indexed address): The Ethereum address of the node for which statistics were updated.
  - `timestamp` (uint64): The timestamp for which statistics were updated.
  - `pbftCount` (uint256): The updated count of PBFT consensus events for the node.

---

This specification document outlines the purpose, data structure definitions, and methods implemented in the `NodeContinuityOracle` contract. It serves as a reference for understanding the functionality and usage of the contract on the blockchain.
