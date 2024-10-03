# ERC20Snapshot
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/ERC20Snapshot.sol)

**Inherits:**
ERC20, [ISnapshot](/contracts/interfaces/ISnapshot.sol/interface.ISnapshot.md)

*This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
total supply at the time are recorded for later access.
This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
used to create an efficient ERC20 forking mechanism.
Snapshots are created by the internal [_snapshot](/contracts/ERC20Snapshot.sol/abstract.ERC20Snapshot.md#_snapshot) function, which will emit the {Snapshot} event and return a
snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
and the account address.
NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
alternative consider {ERC20Votes}.
==== Gas Costs
Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
smaller since identical balances in subsequent snapshots are stored as a single entry.
There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
transfers will have normal cost until the next snapshot, and so on.*


## State Variables
### _accountBalanceSnapshots

```solidity
mapping(address => Snapshots) private _accountBalanceSnapshots;
```


### _totalSupplySnapshots

```solidity
Snapshots private _totalSupplySnapshots;
```


### _contractDeposits

```solidity
mapping(address => uint256) private _contractDeposits;
```


### _yieldBearingContracts

```solidity
mapping(address => bool) private _yieldBearingContracts;
```


### _currentSnapshotId

```solidity
uint256 private _currentSnapshotId;
```


## Functions
### _snapshot

*Creates a new snapshot and returns its snapshot id.
Emits a [Snapshot](/contracts/ERC20Snapshot.sol/abstract.ERC20Snapshot.md#snapshot) event that contains the same id.
{_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
set of accounts, for example using {AccessControl}, or it may be open to the public.
[WARNING]
====
While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
you must consider that it can potentially be used by attackers in two ways.
First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
section above.
We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
====*


```solidity
function _snapshot() internal virtual returns (uint256);
```

### _setYieldBearingContract

*Set a yield bearing contract*


```solidity
function _setYieldBearingContract(address contractAddress) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|the contract address Yield-bearing concept is used to track the contract deposits of addresses sending(depositing) tokens to yield bearing contracts This is used to properly forward yields of the extending rebasing token to the depositors in case of contracts that are not aware of the rebasing token(non yield bearing contracts) Contracts that are aware of the rebasing token are added to the yield bearing contracts mapping and are reciving the yields from the extending rebasing token|


### isYieldBearingContract

*Check if a contract is a yield bearing contract*


```solidity
function isYieldBearingContract(address contractAddress) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|the contract address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool true if the contract is a yield bearing contract, false otherwise|


### _getCurrentSnapshotId

*Get the current snapshotId*


```solidity
function _getCurrentSnapshotId() internal view virtual returns (uint256);
```

### contractDepositOf

*Get the contract deposit of an address*


```solidity
function contractDepositOf(address account) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the contract deposit of the address|


### balanceOfAt

*Retrieves the balance of `account` at the time `snapshotId` was created.*


```solidity
function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the address|
|`snapshotId`|`uint256`|the snapshot id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the balance of the address at the time of the snapshot|


### totalSupplyAt

*Retrieves the total supply at the time `snapshotId` was created.*


```solidity
function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`|the snapshot id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the total supply at the time of the snapshot|


### contractDepositOfAt

*Retrieves the contract deposit of `account` at the time `snapshotId` was created.*


```solidity
function contractDepositOfAt(address account, uint256 snapshotId) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the address|
|`snapshotId`|`uint256`|the snapshot id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the contract deposit of the address at the time of the snapshot|


### _isContract


```solidity
function _isContract(address account) internal view returns (bool);
```

### _update

This method is modified to include the contract deposits in the snapshots

*Update balance and/or total supply snapshots before the values are modified. This is implemented
in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.*


```solidity
function _update(address from, address to, uint256 amount) internal virtual override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|the address|
|`to`|`address`|the address|
|`amount`|`uint256`|the amount|


### _valueAt

*Retrieves the value at the time `snapshotId` was created.*


```solidity
function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`|the snapshot id|
|`snapshots`|`Snapshots`|the snapshots|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool true if the value was found, false otherwise|
|`<none>`|`uint256`|uint256 the value at the time of the snapshot|


### _contractValueAt

*Retrieves the contract deposit of `account` at the time `snapshotId` was created.*


```solidity
function _contractValueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`|the snapshot id|
|`snapshots`|`Snapshots`|the snapshots|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool true if the value was found, false otherwise|
|`<none>`|`uint256`|uint256 the value at the time of the snapshot|


### _updateAccountSnapshot

*Update the balance snapshot of an account*


```solidity
function _updateAccountSnapshot(address account) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|the address|


### _updateTotalSupplySnapshot

*Update the total supply snapshot*


```solidity
function _updateTotalSupplySnapshot() private;
```

### _updateSnapshot

*Update the snapshot*


```solidity
function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue, uint256 currentContractDeposit) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshots`|`Snapshots`|the snapshots|
|`currentValue`|`uint256`|the current value|
|`currentContractDeposit`|`uint256`|the current contract deposit|


### _updateContractSnapshot

*Update the contract snapshot*


```solidity
function _updateContractSnapshot(address contractAddress) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|the contract address|


### _lastSnapshotId

*Retrieve the last snapshot id*


```solidity
function _lastSnapshotId(uint256[] storage ids) private view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ids`|`uint256[]`|the snapshot ids|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the last snapshot id|


## Events
### Snapshot
*Emitted by [_snapshot](/contracts/ERC20Snapshot.sol/abstract.ERC20Snapshot.md#_snapshot) when a snapshot identified by `id` is created.*


```solidity
event Snapshot(uint256 id);
```

## Structs
### Snapshots

```solidity
struct Snapshots {
    uint256[] ids;
    uint256[] values;
    uint256[] contractDeposits;
}
```

