# TestSetup
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/SetUp.t.sol)

**Inherits:**
Test


## State Variables
### lara

```solidity
LaraHarness lara;
```


### mockApyOracle

```solidity
ApyOracle mockApyOracle;
```


### mockDpos

```solidity
MockDpos mockDpos;
```


### stTaraToken

```solidity
StakedNativeAsset stTaraToken;
```


### treasuryAddress

```solidity
address treasuryAddress = address(9999);
```


### numValidators

```solidity
uint16 numValidators = 12;
```


### validators

```solidity
address[] validators = new address[](numValidators);
```


## Functions
### fallback


```solidity
fallback() external payable;
```

### receive


```solidity
receive() external payable;
```

### setupValidators


```solidity
function setupValidators() public;
```

### setupApyOracle


```solidity
function setupApyOracle() public;
```

### setupLara


```solidity
function setupLara() public;
```

### setupLaraWithCommission


```solidity
function setupLaraWithCommission(uint256 commission) public;
```

### findValidatorWithStake


```solidity
function findValidatorWithStake(uint256 stake) public view returns (address);
```

### batchUpdateNodeData


```solidity
function batchUpdateNodeData(uint16 multiplier, bool reverse) public;
```

### calculateSlice


```solidity
function calculateSlice(uint256 amount, uint256 supply) public pure returns (uint256);
```

