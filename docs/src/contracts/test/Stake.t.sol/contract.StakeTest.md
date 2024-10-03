# StakeTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/Stake.t.sol)

**Inherits:**
Test, [TestSetup](/contracts/test/SetUp.t.sol/abstract.TestSetup.md)


## State Variables
### epochDuration

```solidity
uint256 epochDuration = 0;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### stakeAndUnstake


```solidity
function stakeAndUnstake(uint256 amount) public;
```

### stakeAndCancelUnstake


```solidity
function stakeAndCancelUnstake(uint256 amount) public;
```

### test_StakeAndUnstake


```solidity
function test_StakeAndUnstake() public;
```

### test_Revert_On_StakeAmountTooLow


```solidity
function test_Revert_On_StakeAmountTooLow() public;
```

### tes_Revert_On_StakeValueTooLow


```solidity
function tes_Revert_On_StakeValueTooLow() public;
```

### test_Revert_On_UnstakeAmountNotApproved


```solidity
function test_Revert_On_UnstakeAmountNotApproved() public;
```

### testFuzz_stakeAndUnstake


```solidity
function testFuzz_stakeAndUnstake(uint256 amount) public;
```

### testFuzz_Revert_On_unstakeMoreThanStaked


```solidity
function testFuzz_Revert_On_unstakeMoreThanStaked(uint256 amount) public;
```

### test_stakeAndCancelUndelegate


```solidity
function test_stakeAndCancelUndelegate() public;
```

### testFuzz_stakeAndCancelUndelegate


```solidity
function testFuzz_stakeAndCancelUndelegate(uint256 amount) public;
```

### invariant_stakeAndCancelUndelegate


```solidity
function invariant_stakeAndCancelUndelegate() public;
```

