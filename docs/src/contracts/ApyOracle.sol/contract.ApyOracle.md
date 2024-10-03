# ApyOracle
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/ApyOracle.sol)

**Inherits:**
[IApyOracle](/contracts/interfaces/IApyOracle.sol/interface.IApyOracle.md), OwnableUpgradeable, UUPSUpgradeable

*This contract implements the IApyOracle interface and provides methods for managing nodes and delegations.*


## State Variables
### maxValidatorStakeCapacity
*Maximum stake capacity for a validator*


```solidity
uint256 public maxValidatorStakeCapacity;
```


### nodeCount
*Number of nodes*


```solidity
uint256 public nodeCount;
```


### DATA_FEED
*Data feed address*


```solidity
address public DATA_FEED;
```


### lara
*Lara contract address*


```solidity
address public lara;
```


### DPOS
*DPOS contract address*


```solidity
DposInterface public DPOS;
```


### nodesList
*List of nodes*


```solidity
address[] public nodesList;
```


### nodes
*Mapping of node data*


```solidity
mapping(address => IApyOracle.NodeData) public nodes;
```


## Functions
### constructor


```solidity
constructor();
```

### initialize

*Initializes the contract with the given data feed and DPOS contract addresses.*


```solidity
function initialize(address dataFeed, address dpos) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dataFeed`|`address`|The address of the data feed contract.|
|`dpos`|`address`|The address of the DPOS contract.|


### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### OnlyDataFeed

*Modifier to make a function callable only by the data feed contract.*


```solidity
modifier OnlyDataFeed();
```

### OnlyLara

*Modifier to make a function callable only by the Lara contract.*


```solidity
modifier OnlyLara();
```

### setLara

*Sets the Lara contract address.*


```solidity
function setLara(address _lara) external OnlyDataFeed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lara`|`address`|The address of the Lara contract.|


### getNodeCount

*Returns the number of nodes.*


```solidity
function getNodeCount() external view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The number of nodes.|


### getRebalanceList

*Returns a list of tentative re-delegations based on the current validators.*


```solidity
function getRebalanceList(TentativeDelegation[] memory currentValidators)
    external
    override
    OnlyLara
    returns (TentativeReDelegation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentValidators`|`TentativeDelegation[]`|The current validators.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`TentativeReDelegation[]`|An array of tentative re-delegations.|


### getNodesForDelegation

*Returns a list of nodes that can be delegated to, along with the amount that can be delegated to each node.*


```solidity
function getNodesForDelegation(uint256 amount) external OnlyLara returns (TentativeDelegation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to be delegated.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`TentativeDelegation[]`|An array of tentative delegations.|


### updateNodeCount

*Updates the node count.*


```solidity
function updateNodeCount(uint256 count) external override OnlyDataFeed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`count`|`uint256`|The new node count.|


### getDataFeedAddress

*Returns the address of the data feed contract.*


```solidity
function getDataFeedAddress() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the data feed contract.|


### getNodeData

*Returns the data of a specific node.*


```solidity
function getNodeData(address node) external view override returns (IApyOracle.NodeData memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`address`|The address of the node.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IApyOracle.NodeData`|The data of the node.|


### batchUpdateNodeData

*Updates the data of multiple nodes at once.*


```solidity
function batchUpdateNodeData(IApyOracle.NodeData[] memory data) external override OnlyDataFeed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`IApyOracle.NodeData[]`|An array of node data.|


### updateNodeData

*Updates the data of a specific node.*


```solidity
function updateNodeData(address node, NodeData memory data) external override OnlyDataFeed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`node`|`address`|The address of the node.|
|`data`|`NodeData`|The new data of the node.|


### setMaxValidatorStakeCapacity

*Sets the maximum stake capacity for a validator.*


```solidity
function setMaxValidatorStakeCapacity(uint256 capacity) external OnlyDataFeed;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`capacity`|`uint256`|The new maximum stake capacity.|


### sortTentativeDelegationsByRating

*Sorts an array of tentative delegations by rating.*


```solidity
function sortTentativeDelegationsByRating(TentativeDelegation[] memory delegations)
    private
    pure
    returns (TentativeDelegation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegations`|`TentativeDelegation[]`|The array of tentative delegations to sort.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`TentativeDelegation[]`|The sorted array of tentative delegations.|


