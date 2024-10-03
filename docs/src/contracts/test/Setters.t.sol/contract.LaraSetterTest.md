# LaraSetterTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/Setters.t.sol)

**Inherits:**
Test, [TestSetup](/contracts/test/SetUp.t.sol/abstract.TestSetup.md)


## State Variables
### delegators

```solidity
address[] delegators = new address[](6);
```


## Functions
### setupDelegators


```solidity
function setupDelegators() private;
```

### setUp


```solidity
function setUp() public;
```

### testFuzz_setMaxValdiatorStakeCapacity


```solidity
function testFuzz_setMaxValdiatorStakeCapacity(address setter) public;
```

### testFuzz_setMinStakeAmount


```solidity
function testFuzz_setMinStakeAmount(address setter) public;
```

