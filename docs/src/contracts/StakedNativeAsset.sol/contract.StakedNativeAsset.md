# StakedNativeAsset
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/StakedNativeAsset.sol)

**Inherits:**
[ERC20Snapshot](/contracts/ERC20Snapshot.sol/abstract.ERC20Snapshot.md), Ownable, Pausable, [IstTara](/contracts/interfaces/IstTara.sol/interface.IstTara.md)


## State Variables
### lara

```solidity
address public lara;
```


## Functions
### constructor


```solidity
constructor() ERC20("Staked TARA", "stTARA") Ownable(msg.sender) Pausable();
```

### onlyLara

*Modifier to ensure only Lara can call a function*


```solidity
modifier onlyLara();
```

### cumulativeBalanceOf

In case the user is the wstTARA contract, the function will return the wstTARA balance of the wstTARA contract,
ignoring the stTARA balance of the wstTARA contract(locked tokens).

*Function to get the cumulative balance of a user between both stTARA and wstTARA*


```solidity
function cumulativeBalanceOf(address user) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The cumulative balance of the user|


### cumulativeBalanceOfAt

In case the user is the wstTARA contract, the function will return the wstTARA balance of the wstTARA contract,
ignoring the stTARA balance of the wstTARA contract(locked tokens).

*Function to get the cumulative balance of a user between both stTARA and wstTARA at a specific snapshot ID*


```solidity
function cumulativeBalanceOfAt(address user, uint256 snapshotId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user|
|`snapshotId`|`uint256`|The snapshot ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The cumulative balance of the user at the snapshot ID|


### totalSupplyAt

if smart contract, return balanceOfAt() , else, to EOA return balanceOfAt() + wstTARA.balanceOfAt()

if the user is the wstTARA contract, at any given point the balanceOfAt(address(wstTARA), snapshotId)
must be equal to the totalSupplyAt(snapshotId)

However, for proper reward distribution, we need to return the current balance of the wstTARA contract in wstTARA

*Retrieves the total supply at the time `snapshotId` was created.*


```solidity
function totalSupplyAt(uint256 snapshotId) public view override(ERC20Snapshot, IstTara) returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`|the snapshot id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256 the total supply at the time of the snapshot|


### setYieldBearingContract

*Function to set the yield bearing contract address*


```solidity
function setYieldBearingContract(address contractAddress) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|The address of the yield bearing contract Yield bearing contracts are contracts that's balance attribute to stTARA rewards.|


### setLaraAddress

*Function to set the Lara contract address*


```solidity
function setLaraAddress(address _lara) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lara`|`address`||


### snapshot

*Function to take a snapshot of the tracked contract internal values(most notably balances and contract deposits)*


```solidity
function snapshot() external override onlyLara returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the snapshot id|


### mint


```solidity
function mint(address recipient, uint256 amount) external onlyLara;
```

### burn


```solidity
function burn(address user, uint256 amount) external onlyLara;
```

## Errors
### InsufficientUserAllowanceForBurn

```solidity
error InsufficientUserAllowanceForBurn(uint256 amount, uint256 senderBalance, uint256 protocolBalance);
```

