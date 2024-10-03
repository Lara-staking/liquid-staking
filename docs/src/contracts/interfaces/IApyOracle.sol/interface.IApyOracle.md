# IApyOracle
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/IApyOracle.sol)

*This interface defines the methods for APY Oracle*


## Functions
### getNodeCount

*Function to get the node count*


```solidity
function getNodeCount() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the node count|


### getNodesForDelegation

*Function to get nodes for delegation*


```solidity
function getNodesForDelegation(uint256 amount) external returns (TentativeDelegation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to delegate|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`TentativeDelegation[]`|the nodes for delegation|


### getRebalanceList

*Function to get rebalance list*


```solidity
function getRebalanceList(TentativeDelegation[] memory currentValidators)
    external
    returns (TentativeReDelegation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentValidators`|`TentativeDelegation[]`|the current validators|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`TentativeReDelegation[]`|the rebalance list|


### updateNodeCount

*Function to update the node count*


```solidity
function updateNodeCount(uint256 count) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`count`|`uint256`|the count to update|


### batchUpdateNodeData

*Function to batch update node data*


```solidity
function batchUpdateNodeData(IApyOracle.NodeData[] memory data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`IApyOracle.NodeData[]`|the data to update|


### getNodeData

*Function to get node data*


```solidity
function getNodeData(address node) external view returns (NodeData memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`address`|the node to get|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`NodeData`|the node data|


### updateNodeData

*Function to update node data*


```solidity
function updateNodeData(address node, NodeData memory data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`address`|the node to update|
|`data`|`NodeData`|the data to update|


### getDataFeedAddress

*Function to get data feed address*


```solidity
function getDataFeedAddress() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|the data feed address|


## Events
### NodeDataUpdated
*Event to be emitted when node data is updated*


```solidity
event NodeDataUpdated(address indexed node, uint16 apy, uint256 pbftCount);
```

### MaxValidatorStakeUpdated
*Event to be emitted when node stake room is updated*


```solidity
event MaxValidatorStakeUpdated(uint256 maxValidatorStake);
```

## Structs
### NodeData
*Struct to store node data*


```solidity
struct NodeData {
    uint256 rating;
    address account;
    uint64 fromBlock;
    uint64 toBlock;
    uint16 rank;
    uint16 apy;
}
```

### TentativeDelegation
*Struct to store tentative delegation data*


```solidity
struct TentativeDelegation {
    address validator;
    uint256 amount;
    uint256 rating;
}
```

### TentativeReDelegation
*Struct to store tentative redelegation data*


```solidity
struct TentativeReDelegation {
    address from;
    address to;
    uint256 amount;
    uint256 toRating;
}
```

