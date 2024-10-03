# MockDpos
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/mocks/MockDpos.sol)

**Inherits:**
[MockIDPOS](/contracts/mocks/MockIDPOS.sol/interface.MockIDPOS.md)


## State Variables
### undelegationId

```solidity
uint64 public undelegationId = 1;
```


### validators

```solidity
mapping(address => MockIDPOS.ValidatorData) public validators;
```


### totalDelegations

```solidity
mapping(address => uint256) public totalDelegations;
```


### delegations

```solidity
mapping(address => MockIDPOS.DelegationData[]) public delegations;
```


### validatorDatas

```solidity
MockIDPOS.ValidatorData[] validatorDatas;
```


### undelegations

```solidity
mapping(address => mapping(uint256 => Undelegation)) public undelegations;
```


### maxValidatorStakeCapacity

```solidity
uint256 public maxValidatorStakeCapacity;
```


### UNDELEGATION_DELAY_BLOCKS

```solidity
uint256 public constant UNDELEGATION_DELAY_BLOCKS = 5000;
```


## Functions
### constructor


```solidity
constructor(address[] memory _internalValidators) payable;
```

### isValidatorRegistered


```solidity
function isValidatorRegistered(address validator) external view returns (bool);
```

### getDelegations


```solidity
function getDelegations(address delegator, uint32)
    external
    view
    returns (MockIDPOS.DelegationData[] memory _delegations, bool end);
```

### getTotalDelegation


```solidity
function getTotalDelegation(address delegator) external view returns (uint256 total_delegation);
```

### getValidator


```solidity
function getValidator(address validator) external view returns (MockIDPOS.ValidatorBasicInfo memory);
```

### getValidators


```solidity
function getValidators(uint32 batch) external view returns (ValidatorData[] memory validatorsOut, bool end);
```

### getValidatorsFor


```solidity
function getValidatorsFor(address owner, uint32 batch)
    external
    view
    returns (ValidatorData[] memory validatorsOut, bool end);
```

### delegate


```solidity
function delegate(address validator) external payable override;
```

### _alreadyDelegatedToValidator


```solidity
function _alreadyDelegatedToValidator(address validator, address delegator) internal view returns (int256);
```

### registerValidator


```solidity
function registerValidator(
    address validator,
    bytes memory proof,
    bytes memory vrf_key,
    uint16 commission,
    string calldata description,
    string calldata endpoint
) external payable override;
```

### undelegateV2


```solidity
function undelegateV2(address validator, uint256 amount) external override returns (uint64 id);
```

### claimAllRewards


```solidity
function claimAllRewards() external;
```

### reDelegate


```solidity
function reDelegate(address validator_from, address validator_to, uint256 amount) external;
```

### confirmUndelegateV2


```solidity
function confirmUndelegateV2(address validator, uint64 id) external override;
```

### cancelUndelegateV2


```solidity
function cancelUndelegateV2(address validator, uint64 id) external override;
```

### getUndelegationV2


```solidity
function getUndelegationV2(address, address validator, uint64 undelegation_id)
    external
    view
    returns (MockIDPOS.UndelegationV2Data memory undelegation_v2);
```

## Events
### TotalStake

```solidity
event TotalStake(uint256 totalStake);
```

### DelegationRewards

```solidity
event DelegationRewards(uint256 totalStakes, uint256 totalRewards);
```

## Structs
### Undelegation

```solidity
struct Undelegation {
    uint256 id;
    address delegator;
    uint256 amount;
    uint256 blockNumberClaimable;
}
```

