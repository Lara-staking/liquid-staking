# ILara
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/ILara.sol)

Lara is a staking contract that allows users to stake their TARA tokens and earn rewards.

It is a general staking contract that can be used for any staking purpose.

Use this interface to loose coupling between Lara and other contracts.

*This interface defines the methods for the Lara contract*


## Functions
### compound

*Function to compound the rewards into the staking contract*


```solidity
function compound(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to compound|


### isValidatorRegistered

*Function to check if a validator is registered*


```solidity
function isValidatorRegistered(address validator) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`validator`|`address`|The address of the validator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|A boolean indicating if the validator is registered|


### setCommissionDiscounts

*Function to set the commission discounts*

*Only callable by the owner*


```solidity
function setCommissionDiscounts(address staker, uint32 discount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|the staker address|
|`discount`|`uint32`|the discount|


### setEpochDuration

Setter for epochDuration


```solidity
function setEpochDuration(uint256 _epochDuration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_epochDuration`|`uint256`|new epoch duration (in seconds)|


### setCommission

*Function to set the commission*


```solidity
function setCommission(uint256 _commission) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_commission`|`uint256`|The new commission|


### setTreasuryAddress

*Function to set the treasury address*


```solidity
function setTreasuryAddress(address _treasuryAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasuryAddress`|`address`|The new treasury address|


### setMaxValidatorStakeCapacity

*Function to set the maximum validator stake capacity*


```solidity
function setMaxValidatorStakeCapacity(uint256 _maxValidatorStakeCapacity) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxValidatorStakeCapacity`|`uint256`|The new maximum validator stake capacity|


### setMinStakeAmount

*Function to set the minimum stake amount*


```solidity
function setMinStakeAmount(uint256 _minStakeAmount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minStakeAmount`|`uint256`|The new minimum stake amount|


### stake

Stake function
In the stake function, the user sends the amount of TARA tokens he wants to stake.
This method takes the payment and mints the stTARA tokens to the user.

The tokens are DELEGATED INSTANTLY.

The amount that cannot be delegated is returned to the user.


```solidity
function stake(uint256 amount) external payable returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to stake|


### rebalance

Rebalance method to rebalance the protocol.
The method is intended to be called by anyone, at least every epochDuration blocks.
In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
The method will call the oracle to get the rebalance list and then redelegate the stake.


```solidity
function rebalance() external;
```

### requestUndelegate

Undelegates the amount from one or more validators.
The user needs to provide the amount of stTARA tokens he wants to undelegate. The protocol will burn them.

reverts on missing approval for the amount.


```solidity
function requestUndelegate(uint256 amount) external returns (uint64[] memory undelegation_ids);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of tokens to undelegate|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`undelegation_ids`|`uint64[]`|The ids of the undelegations done|


### confirmUndelegate

Confirm undelegate method to confirm the undelegation of a user from a certain validator.
Will fail if called before the undelegation period is over.

msg.sender is the delegator


```solidity
function confirmUndelegate(uint64 id) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|


### batchConfirmUndelegate

Batch confirm undelegate method to confirm the undelegation of a user from a certain validator.
Will fail if called before the undelegation period is over.

msg.sender is the delegator


```solidity
function batchConfirmUndelegate(uint64[] calldata ids) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ids`|`uint64[]`|the ids of the undelegations|


### cancelUndelegate

Cancel undelegate method to cancel the undelegation of a user from a certain validator.
The undelegated value will be returned to the origin validator.


```solidity
function cancelUndelegate(uint64 id) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|


### batchCancelUndelegate

Batch cancel undelegate method to cancel the undelegation of a user from a certain validator.
The undelegated value will be returned to the origin validator.


```solidity
function batchCancelUndelegate(uint64[] calldata ids) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ids`|`uint64[]`|the ids of the undelegations|


### snapshot

method to create a protocol snapshot.
A protocol snapshot can be done once every epochDuration blocks.
The method will claim all rewards from the DPOS contract.


```solidity
function snapshot() external returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the snapshot id of the made stTARA snapshot|


### distributeRewardsForSnapshot

*Function to distribute rewards for a snapshot*


```solidity
function distributeRewardsForSnapshot(address staker, uint256 snapshotId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|the staker address|
|`snapshotId`|`uint256`|the snapshot id|


## Events
### Staked
*Event emitted when a user stakes*


```solidity
event Staked(address indexed user, uint256 indexed amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|the user who staked|
|`amount`|`uint256`|the amount of the stake|

### SnapshotTaken
*Event emitted when a snapshot was taken*


```solidity
event SnapshotTaken(
    uint256 indexed snapshotId, uint256 indexed totalDelegation, uint256 indexed totalRewards, uint256 nextSnapshotBlock
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`||
|`totalDelegation`|`uint256`|the total delegation|
|`totalRewards`|`uint256`|the total rewards|
|`nextSnapshotBlock`|`uint256`|the block number of the next snapshot|

### AllRewardsClaimed
*Event emitted when all protocol level rewards are claimed from the DPOS Contract*


```solidity
event AllRewardsClaimed(uint256 indexed amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of the rewards|

### RedelegationRewardsClaimed
*Event emitted when redelegation rewards are claimed*


```solidity
event RedelegationRewardsClaimed(uint256 indexed amount, address indexed validator);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of the rewards|
|`validator`|`address`|the validator to which the rewards are claimed|

### Undelegated
Event emitted when an undelegation request is registered


```solidity
event Undelegated(uint64 indexed id, address indexed user, address indexed validator, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|
|`user`|`address`|the user who requested the undelegation|
|`validator`|`address`|the validator to which the user undelegated|
|`amount`|`uint256`|the amount of the undelegation|

### UndelegationConfirmed
*Event emitted when a user confirms an undelegation*


```solidity
event UndelegationConfirmed(uint64 indexed id, address indexed user);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|
|`user`|`address`|the user who confirmed the undelegation|

### UndelegationCancelled
*Event emitted when a user cancels an undelegation*


```solidity
event UndelegationCancelled(uint64 indexed id, address indexed user);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|
|`user`|`address`|the user who cancelled the undelegation|

### TaraSent
*Event emitted when Tara is sent*


```solidity
event TaraSent(address indexed user, uint256 indexed amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|the address who sent the Tara|
|`amount`|`uint256`|the amount of the Tara sent|

### CommissionWithdrawn
*Event emitted when commission is withdrawn for an epoch to the treasury*


```solidity
event CommissionWithdrawn(address indexed user, uint256 indexed amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|the treasury address|
|`amount`|`uint256`|the amount of the commission withdrawn|

### CommissionChanged
*Event emitted when commission is changed*


```solidity
event CommissionChanged(uint256 indexed newCommission);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newCommission`|`uint256`|the new commission|

### TreasuryChanged
*Event emitted when treasury is changed*


```solidity
event TreasuryChanged(address indexed newTreasury);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newTreasury`|`address`|the new treasury address|

### RewardsClaimedForSnapshot
*Event emitted when rewards are claimed for a snapshot*


```solidity
event RewardsClaimedForSnapshot(
    uint256 indexed snapshotId, address indexed staker, uint256 indexed reward, uint256 balance
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`snapshotId`|`uint256`|the id of the snapshot|
|`staker`|`address`|the staker address|
|`reward`|`uint256`|the reward amount|
|`balance`|`uint256`|the balance of the staker|

