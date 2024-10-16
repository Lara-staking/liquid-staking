# ManyValidatorEpochTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/EpochLotsOfValidators.t.sol)

**Inherits:**
Test, [ManyValidatorsTestSetup](/contracts/test/SetUpLotsOfValidators.t.sol/abstract.ManyValidatorsTestSetup.md)


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

### runWithDiscounts


```solidity
function runWithDiscounts(uint8 epochNumbers) public;
```

### test_SingleEpoch


```solidity
function test_SingleEpoch() public;
```

### test_RunMultipleEpochs


```solidity
function test_RunMultipleEpochs() public;
```

## Events
### ExpectedReward

```solidity
event ExpectedReward(uint256 expectedReward);
```

