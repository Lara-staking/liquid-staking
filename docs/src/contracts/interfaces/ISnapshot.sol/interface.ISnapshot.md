# ISnapshot
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/ISnapshot.sol)

*Interface for the IstTara contract, extending IERC20*


## Functions
### snapshot

*Function to take a snapshot of the tracked contract internal values(most notably balances and contract deposits)*


```solidity
function snapshot() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the snapshot id|


