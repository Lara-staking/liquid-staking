# LaraTokenPresaleTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/LaraTokenPresale.t.sol)

**Inherits:**
Test


## State Variables
### laraToken

```solidity
LaraToken laraToken;
```


### treasuryAddress

```solidity
address treasuryAddress;
```


### presaleRate

```solidity
uint8 presaleRate = 4;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### testPresaleGivesRightAmounts


```solidity
function testPresaleGivesRightAmounts() public;
```

### test_successiveSwaps_Lockout


```solidity
function test_successiveSwaps_Lockout() public;
```

### test_presaleRunning_allTokensClaimed_swapsFail


```solidity
function test_presaleRunning_allTokensClaimed_swapsFail() public;
```

### testFuzz_PresaleRandomAmounts


```solidity
function testFuzz_PresaleRandomAmounts(uint256 amount) public;
```

### testEndPresale_failsOnBlockFirstTheSucceeds


```solidity
function testEndPresale_failsOnBlockFirstTheSucceeds() public;
```

