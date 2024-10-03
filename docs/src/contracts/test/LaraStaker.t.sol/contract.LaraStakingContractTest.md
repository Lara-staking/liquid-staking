# LaraStakingContractTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/LaraStaker.t.sol)

**Inherits:**
Test


## State Variables
### stakingContract

```solidity
LaraStaking stakingContract;
```


### rewardToken

```solidity
veLara rewardToken;
```


### stakingToken

```solidity
LaraToken stakingToken;
```


### user

```solidity
address user = address(0x123);
```


### treasury

```solidity
address treasury = address(0x789);
```


### BLOCK_TIME

```solidity
uint256 BLOCK_TIME = 4;
```


### SECONDS_PER_YEAR

```solidity
uint256 SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
```


### APY

```solidity
uint256 APY = 13;
```


### MATURITY_BLOCK_COUNT

```solidity
uint256 MATURITY_BLOCK_COUNT = 426445;
```


### STAKED_AMOUNT

```solidity
uint256 STAKED_AMOUNT = 100 ether;
```


## Functions
### setUp


```solidity
function setUp() public;
```

### test_simpleDeposit_ConvertsLaraToVeLara


```solidity
function test_simpleDeposit_ConvertsLaraToVeLara() public;
```

### simulateSpecificMaturity


```solidity
function simulateSpecificMaturity(uint256 maturityBlockCount) internal;
```

### test_APYCalculation_6Months_FullMaturity


```solidity
function test_APYCalculation_6Months_FullMaturity() public;
```

### test_APYCalculation_3Months_HalfMaturity


```solidity
function test_APYCalculation_3Months_HalfMaturity() public;
```

### test_APYCalculation_9Months_OverlyMature


```solidity
function test_APYCalculation_9Months_OverlyMature() public;
```

### testFuzz_APYCalculation_RandomMaturity


```solidity
function testFuzz_APYCalculation_RandomMaturity(uint256 randomMaturity) public;
```

### test_Upgrade


```solidity
function test_Upgrade() public;
```

