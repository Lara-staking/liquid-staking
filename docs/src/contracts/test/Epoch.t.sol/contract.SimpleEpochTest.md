# SimpleEpochTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/Epoch.t.sol)

**Inherits:**
Test, [TestSetup](/contracts/test/SetUp.t.sol/abstract.TestSetup.md)


## State Variables
### epochDuration

```solidity
uint256 epochDuration = 0;
```


### balancesBefore

```solidity
uint256[] balancesBefore;
```


### stakers

```solidity
address[] stakers;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### stake


```solidity
function stake(bool withCommissionsDiscounts) public;
```

### run


```solidity
function run(uint8 epochNumbers) public;
```

### runWithDiscounts


```solidity
function runWithDiscounts(uint8 epochNumbers) public;
```

### test_simpleCommissionMaths


```solidity
function test_simpleCommissionMaths() public pure;
```

### test_SingleEpoch


```solidity
function test_SingleEpoch() public;
```

### test_RunMultipleEpochs


```solidity
function test_RunMultipleEpochs() public;
```

### test_CommissionDiscounts


```solidity
function test_CommissionDiscounts() public;
```

## Events
### ExpectedReward

```solidity
event ExpectedReward(uint256 expectedReward);
```

### ExcessReward

```solidity
event ExcessReward(uint256 excessReward);
```

### Discount

```solidity
event Discount(uint32 discount);
```

### BalanceParts

```solidity
event BalanceParts(uint256 currentBalance, uint256 expectedReward, uint256 balanceBefore);
```

### StakerRewardDetails

```solidity
event StakerRewardDetails(
    uint32 stakerIndex, uint256 slice, uint256 discount, uint256 expectedReward, uint256 actualReward
);
```

### RewardSummary

```solidity
event RewardSummary(
    uint256 expectedDelegatorRewards, uint256 totalExpectedRewardsWithDiscounts, uint256 totalActualRewards
);
```

