# IStaking20
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/IStaking20.sol)

**Author:**
thirdweb


## Functions
### stake

Stake ERC20 Tokens.


```solidity
function stake(uint256 amount) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|   Amount to stake.|


### withdraw

Withdraw staked tokens.


```solidity
function withdraw(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|   Amount to withdraw.|


### claimRewards

Claim accumulated rewards.


```solidity
function claimRewards() external;
```

### getStakeInfo

View amount staked and total rewards for a user.


```solidity
function getStakeInfo(address staker) external view returns (uint256 _tokensStaked, uint256 _rewards);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|   Address for which to calculate rewards.|


## Events
### TokensStaked
*Emitted when tokens are staked.*


```solidity
event TokensStaked(address indexed staker, uint256 amount);
```

### TokensWithdrawn
*Emitted when tokens are withdrawn.*


```solidity
event TokensWithdrawn(address indexed staker, uint256 amount);
```

### RewardsClaimed
*Emitted when a staker claims staking rewards.*


```solidity
event RewardsClaimed(address indexed staker, uint256 rewardAmount);
```

### UpdatedTimeUnit
*Emitted when contract admin updates timeUnit.*


```solidity
event UpdatedTimeUnit(uint256 oldTimeUnit, uint256 newTimeUnit);
```

### UpdatedRewardRatio
*Emitted when contract admin updates the reward ratio.*


```solidity
event UpdatedRewardRatio(uint256 oldNumerator, uint256 newNumerator, uint256 oldDenominator, uint256 newDenominator);
```

### UpdatedMinStakeAmount
*Emitted when contract admin updates minimum staking amount.*


```solidity
event UpdatedMinStakeAmount(uint256 oldAmount, uint256 newAmount);
```

## Structs
### Staker
Staker Info.


```solidity
struct Staker {
    uint256 amountStaked;
    uint256 unclaimedRewards;
    uint128 timeOfLastUpdate;
    uint64 conditionIdOflastUpdate;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`amountStaked`|`uint256`|            Total number of tokens staked by the staker.|
|`unclaimedRewards`|`uint256`|        Rewards accumulated but not claimed by user yet.|
|`timeOfLastUpdate`|`uint128`|        Last reward-update timestamp.|
|`conditionIdOflastUpdate`|`uint64`| Condition-Id when rewards were last updated for user.|

### StakingCondition
Staking Condition.


```solidity
struct StakingCondition {
    uint80 timeUnit;
    uint80 startTimestamp;
    uint80 endTimestamp;
    uint256 rewardRatioNumerator;
    uint256 rewardRatioDenominator;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`timeUnit`|`uint80`|                Unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.|
|`startTimestamp`|`uint80`|          Condition start timestamp.|
|`endTimestamp`|`uint80`|            Condition end timestamp.|
|`rewardRatioNumerator`|`uint256`|    Rewards ratio is the number of reward tokens for a number of staked tokens, per unit of time.|
|`rewardRatioDenominator`|`uint256`|  Rewards ratio is the number of reward tokens for a number of staked tokens, per unit of time.|

