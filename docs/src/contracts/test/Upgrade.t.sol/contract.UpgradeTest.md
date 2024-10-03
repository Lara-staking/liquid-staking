# UpgradeTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/Upgrade.t.sol)

**Inherits:**
Test


## State Variables
### lara

```solidity
Lara lara;
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

### setUp


```solidity
function setUp() public;
```

### testUpgradeProxy


```solidity
function testUpgradeProxy() public;
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

