# UnstakeTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/Unstake.t.sol)

**Inherits:**
Test, [TestSetup](/contracts/test/SetUp.t.sol/abstract.TestSetup.md)


## State Variables
### epochDuration

```solidity
uint256 epochDuration = 0;
```


### stakes

```solidity
uint256 stakes = 10;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### multipleStakes


```solidity
function multipleStakes(uint256 amount) public;
```

### multipleFullUnstakes


```solidity
function multipleFullUnstakes() public;
```

### testFuzz_stakeAndFullyUnstake


```solidity
function testFuzz_stakeAndFullyUnstake(uint256 amount) public;
```

