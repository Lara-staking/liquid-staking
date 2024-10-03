# IstTara
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/IstTara.sol)

**Inherits:**
IERC20, [ISnapshot](/contracts/interfaces/ISnapshot.sol/interface.ISnapshot.md)

*Interface for the IstTara contract, extending IERC20
This interface is used to handle the stTARA and wstTARA balances of users and contracts,
handling more complex scenarios as yield-bearing contracts and non-yield bearing contracts.
Example scenario:
User 1:
- stTARA balance: 2.5M
- Total stTARA supply: 2.5M
User 2:
- stTARA balance: 5M
- Total stTARA supply: 7.5M
Both users deposit their stTARA into a non-yield-bearing contract.
Uniswap V3 pool:
- stTARA balance: 7.5M
- Total stTARA supply: 7.5M
- All yields should be forwarded from the V3 pool contract to the depsitors.
In this scenario, cumulativeBalanceOfAt(address, snapshotId) would return 0 for all non-yield bearing contracts,
while returning 2.5M and 7.5M for users 1 and 2 respectively.*


## Functions
### mint

*Function to mint new tokens*


```solidity
function mint(address recipient, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The address to receive the newly minted tokens|
|`amount`|`uint256`|The amount of tokens to mint|


### burn

*Function to burn tokens from a specific address*


```solidity
function burn(address user, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address from which tokens will be burnt|
|`amount`|`uint256`|The amount of tokens to burn|


### setLaraAddress

*Function to set the Lara contract address*


```solidity
function setLaraAddress(address laraAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`laraAddress`|`address`|The address of the Lara contract|


### setYieldBearingContract

*Function to set the yield bearing contract address*


```solidity
function setYieldBearingContract(address contractAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|The address of the yield bearing contract Yield bearing contracts are contracts that's balance attribute to stTARA rewards.|


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

*Function to get the total supply at a specific snapshot ID*


```solidity
function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`|The snapshot ID|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The total supply at the snapshot ID|


