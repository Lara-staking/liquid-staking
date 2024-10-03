# LaraTokenBaseTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/LaraTokenBase.t.sol)

**Inherits:**
Test


## State Variables
### laraToken

```solidity
LaraToken public laraToken;
```


### treasury

```solidity
address public treasury;
```


### user1

```solidity
address public user1;
```


### user2

```solidity
address public user2;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### test_InitialState


```solidity
function test_InitialState() public view;
```

### test_StartPresale


```solidity
function test_StartPresale() public;
```

### test_CannotStartPresaleTwice


```solidity
function test_CannotStartPresaleTwice() public;
```

### test_EndPresale


```solidity
function test_EndPresale() public;
```

### test_CannotEndPresaleBeforeDuration


```solidity
function test_CannotEndPresaleBeforeDuration() public;
```

### test_Swap


```solidity
function test_Swap() public;
```

### test_CannotSwapBelowMinimum


```solidity
function test_CannotSwapBelowMinimum() public;
```

### test_CannotSwapAboveUpperLimit


```solidity
function test_CannotSwapAboveUpperLimit() public;
```

### test_SwapCooldown


```solidity
function test_SwapCooldown() public;
```

### test_CannotSwapWhenPresaleNotRunning


```solidity
function test_CannotSwapWhenPresaleNotRunning() public;
```

