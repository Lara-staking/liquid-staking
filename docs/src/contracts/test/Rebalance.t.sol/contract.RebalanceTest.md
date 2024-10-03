# RebalanceTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/Rebalance.t.sol)

**Inherits:**
Test, [TestSetup](/contracts/test/SetUp.t.sol/abstract.TestSetup.md)


## Functions
### setUp


```solidity
function setUp() public;
```

### stake


```solidity
function stake(uint256 amount) private;
```

### testFuzz_testRedelegateStakeToSingleValidator


```solidity
function testFuzz_testRedelegateStakeToSingleValidator(uint256 amount) public;
```

### testFuzz_testRedelegateStakeToMultipleValidators


```solidity
function testFuzz_testRedelegateStakeToMultipleValidators(uint256 amount) public;
```

### testFuzz_testDoNotRedelegateStakeToMultipleValidators


```solidity
function testFuzz_testDoNotRedelegateStakeToMultipleValidators(uint256 amount) public;
```

