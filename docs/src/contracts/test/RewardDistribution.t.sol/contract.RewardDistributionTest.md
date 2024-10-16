# RewardDistributionTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/RewardDistribution.t.sol)

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


### stakedAmount

```solidity
uint256 stakedAmount = 50000 ether;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### stake


```solidity
function stake(bool withCommissionsDiscounts, uint256 noOfStakers) public;
```

### checkRewardsAreRight


```solidity
function checkRewardsAreRight(address singleStaker, uint256 snapshotId, uint256 initialBalance) public;
```

### test_Reverts_On_DoubleClaim


```solidity
function test_Reverts_On_DoubleClaim() public;
```

### test_Reverts_On_DisributeRewards_Check_Violation


```solidity
function test_Reverts_On_DisributeRewards_Check_Violation() public;
```

### test_OneStake_ThenDeposit_In_NonYieldBearing_Contract_NoDoubleRewards


```solidity
function test_OneStake_ThenDeposit_In_NonYieldBearing_Contract_NoDoubleRewards() public;
```

### test_OneStake_ThenDeposit_In_YieldBearing_Contract_NoDoubleRewards


```solidity
function test_OneStake_ThenDeposit_In_YieldBearing_Contract_NoDoubleRewards() public;
```

### test_OneStake_OneEpoch_RewardDistribution


```solidity
function test_OneStake_OneEpoch_RewardDistribution() public;
```

### test_stTARA_OneStake_OneEpoch_RewardDistribution


```solidity
function test_stTARA_OneStake_OneEpoch_RewardDistribution() public;
```

### testFuzz_some_stTARA_MultipleStakes_withDiscounts


```solidity
function testFuzz_some_stTARA_MultipleStakes_withDiscounts(uint32 noOfStakers) public;
```

### test_some_stTara


```solidity
function test_some_stTara() public;
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

### RewardParts

```solidity
event RewardParts(
    uint256 balanceBefore,
    uint256 generalPart,
    uint256 commissionMultiplier,
    uint256 commissionPart,
    uint256 totalReward
);
```

### GeneralParts

```solidity
event GeneralParts(uint256 slice, uint256 snapshotRewards);
```

### SliceParts

```solidity
event SliceParts(uint256 delegatorBalance, uint256 stTaraSupply);
```

