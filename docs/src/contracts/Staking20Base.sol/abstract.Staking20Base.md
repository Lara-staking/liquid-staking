# Staking20Base
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/Staking20Base.sol)

**Inherits:**
ReentrancyGuardUpgradeable, [IStaking20](/contracts/interfaces/IStaking20.sol/interface.IStaking20.md)

**Author:**
thirdweb


## State Variables
### stakingToken
*Address of ERC20 contract -- staked tokens belong to this contract.*


```solidity
address public stakingToken;
```


### stakingTokenDecimals
*Decimals of staking token.*


```solidity
uint16 public stakingTokenDecimals;
```


### rewardTokenDecimals
*Decimals of reward token.*


```solidity
uint16 public rewardTokenDecimals;
```


### nextConditionId
*Next staking condition Id. Tracks number of conditon updates so far.*


```solidity
uint64 private nextConditionId;
```


### stakingTokenBalance
*Total amount of tokens staked in the contract.*


```solidity
uint256 public stakingTokenBalance;
```


### stakersArray
*List of accounts that have staked that token-id.*


```solidity
address[] public stakersArray;
```


### stakers
*Mapping staker address to Staker struct. See {struct IStaking20.Staker}.*


```solidity
mapping(address => Staker) public stakers;
```


### stakingConditions
*Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}*


```solidity
mapping(uint256 => StakingCondition) private stakingConditions;
```


## Functions
### constructor


```solidity
constructor();
```

### __Staking20_init


```solidity
function __Staking20_init(address _stakingToken, uint16 _stakingTokenDecimals, uint16 _rewardTokenDecimals)
    internal
    onlyInitializing;
```

### stake

Stake ERC20 Tokens.

*See [_stake](/contracts/Staking20Base.sol/abstract.Staking20Base.md#_stake). Override that to implement custom logic.*


```solidity
function stake(uint256 _amount) external payable nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|   Amount to stake.|


### withdraw

Withdraw staked ERC20 tokens.

*See [_withdraw](/contracts/Staking20Base.sol/abstract.Staking20Base.md#_withdraw). Override that to implement custom logic.*


```solidity
function withdraw(uint256 _amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|   Amount to withdraw.|


### claimRewards

Claim accumulated rewards.

*See [_claimRewards](/contracts/Staking20Base.sol/abstract.Staking20Base.md#_claimrewards). Override that to implement custom logic.
See {_calculateRewards} for reward-calculation logic.*


```solidity
function claimRewards() external nonReentrant;
```

### setTimeUnit

Set time unit. Set as a number of seconds.
Could be specified as -- x * 1 hours, x * 1 days, etc.

*Only admin/authorized-account can call it.*


```solidity
function setTimeUnit(uint80 _timeUnit) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_timeUnit`|`uint80`|   New time unit.|


### setRewardRatio

Set rewards per unit of time.
Interpreted as (numerator/denominator) rewards per second/per day/etc based on time-unit.
For e.g., ratio of 1/20 would mean 1 reward token for every 20 tokens staked.

*Only admin/authorized-account can call it.*


```solidity
function setRewardRatio(uint256 _numerator, uint256 _denominator) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_numerator`|`uint256`|   Reward ratio numerator.|
|`_denominator`|`uint256`| Reward ratio denominator.|


### getStakeInfo

View amount staked and rewards for a user.


```solidity
function getStakeInfo(address _staker) external view virtual returns (uint256 _tokensStaked, uint256 _rewards);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_staker`|`address`|         Address for which to calculated rewards.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`_tokensStaked`|`uint256`|  Amount of tokens staked.|
|`_rewards`|`uint256`|       Available reward amount.|


### getTimeUnit


```solidity
function getTimeUnit() public view returns (uint80 _timeUnit);
```

### getRewardRatio


```solidity
function getRewardRatio() public view returns (uint256 _numerator, uint256 _denominator);
```

### _stake

*Staking logic. Override to add custom logic.*


```solidity
function _stake(uint256 _amount) internal virtual;
```

### _withdraw

*Withdraw logic. Override to add custom logic.*


```solidity
function _withdraw(uint256 _amount) internal virtual;
```

### _claimRewards

*Logic for claiming rewards. Override to add custom logic.*


```solidity
function _claimRewards() internal virtual;
```

### _availableRewards

*View available rewards for a user.*


```solidity
function _availableRewards(address _staker) internal view virtual returns (uint256 _rewards);
```

### _updateUnclaimedRewardsForStaker

*Update unclaimed rewards for a users. Called for every state change for a user.*


```solidity
function _updateUnclaimedRewardsForStaker(address _staker) internal virtual;
```

### _setStakingCondition

*Set staking conditions.*


```solidity
function _setStakingCondition(uint80 _timeUnit, uint256 _numerator, uint256 _denominator) internal virtual;
```

### _calculateRewards

*Calculate rewards for a staker.*


```solidity
function _calculateRewards(address _staker) internal view virtual returns (uint256 _rewards);
```

### _stakeMsgSender

*Exposes the ability to override the msg sender -- support ERC2771.*


```solidity
function _stakeMsgSender() internal virtual returns (address);
```

### getRewardTokenBalance

View total rewards available in the staking contract.


```solidity
function getRewardTokenBalance() external view virtual returns (uint256 _rewardsAvailableInContract);
```

### _mintRewards

*Mint/Transfer ERC20 rewards to the staker. Must override.*


```solidity
function _mintRewards(address _staker, uint256 _rewards) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_staker`|`address`|   Address for which to calculated rewards.|
|`_rewards`|`uint256`|  Amount of tokens to be given out as reward. For example, override as below to mint ERC20 rewards: ``` function _mintRewards(address _staker, uint256 _rewards) internal override { TokenERC20(rewardTokenAddress).mintTo(_staker, _rewards); } ```|


### _canSetStakeConditions

*Returns whether staking restrictions can be set in given execution context.
Must override.
For example, override as below to restrict access to admin:
```
function _canSetStakeConditions() internal override {
return msg.sender == adminAddress;
}
```*


```solidity
function _canSetStakeConditions() internal view virtual returns (bool);
```

