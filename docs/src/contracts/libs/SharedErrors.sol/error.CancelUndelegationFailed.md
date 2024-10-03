# CancelUndelegationFailed
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/libs/SharedErrors.sol)

It is returned if the undelegation cancellation from a certain validator fails.


```solidity
error CancelUndelegationFailed(address delegator, address validator, uint256 amount, string reason);
```

