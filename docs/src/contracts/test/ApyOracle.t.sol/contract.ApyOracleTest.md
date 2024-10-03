# ApyOracleTest
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/test/ApyOracle.t.sol)

**Inherits:**
[TestSetup](/contracts/test/SetUp.t.sol/abstract.TestSetup.md)


## State Variables
### dataFeedAddress

```solidity
address public dataFeedAddress = address(this);
```


### secondSignerAddress

```solidity
address public secondSignerAddress = address(0x2);
```


## Functions
### setUp


```solidity
function setUp() public;
```

### test_DeployApyOracleAndSetDataFeedAddress


```solidity
function test_DeployApyOracleAndSetDataFeedAddress() public;
```

### test_UpdateAndRetrieveNodeData


```solidity
function test_UpdateAndRetrieveNodeData() public;
```

### test_UnauthorizedUpdateShouldRevert


```solidity
function test_UnauthorizedUpdateShouldRevert() public;
```

