# EpochDurationNotMet
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/libs/SharedErrors.sol)

It is returned if the epoch duration was not met and the method to end was called.


```solidity
error EpochDurationNotMet(uint256 lastEpochStart, uint256 currentBlockNumber, uint256 epochDuration);
```

