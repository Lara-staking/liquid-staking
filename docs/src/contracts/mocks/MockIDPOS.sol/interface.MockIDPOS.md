# MockIDPOS
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/mocks/MockIDPOS.sol)


## Functions
### delegate


```solidity
function delegate(address validator) external payable;
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
) external payable;
```

### getTotalDelegation


```solidity
function getTotalDelegation(address delegator) external view returns (uint256 total_delegation);
```

### getValidator


```solidity
function getValidator(address validator) external view returns (ValidatorBasicInfo memory validator_info);
```

### undelegateV2


```solidity
function undelegateV2(address validator, uint256 amount) external returns (uint64 id);
```

### getValidators


```solidity
function getValidators(uint32 batch) external view returns (ValidatorData[] memory validators, bool end);
```

### getValidatorsFor


```solidity
function getValidatorsFor(address owner, uint32 batch)
    external
    view
    returns (ValidatorData[] memory validators, bool end);
```

### claimAllRewards

Claims staking rewards from all validators (limited by max dag block gas limit) that caller has delegated to


```solidity
function claimAllRewards() external;
```

### reDelegate


```solidity
function reDelegate(address validator_from, address validator_to, uint256 amount) external;
```

### confirmUndelegateV2


```solidity
function confirmUndelegateV2(address validator, uint64 id) external;
```

### cancelUndelegateV2


```solidity
function cancelUndelegateV2(address validator, uint64 id) external;
```

### getUndelegationV2


```solidity
function getUndelegationV2(address delegator, address validator, uint64 undelegation_id)
    external
    view
    returns (UndelegationV2Data memory undelegation_v2);
```

## Events
### Delegated

```solidity
event Delegated(address indexed delegator, address indexed validator, uint256 amount);
```

### Undelegated

```solidity
event Undelegated(uint256 indexed id, address indexed delegator, address indexed validator, uint256 amount);
```

### UndelegateConfirmed

```solidity
event UndelegateConfirmed(uint256 indexed id, address indexed delegator, address indexed validator, uint256 amount);
```

### UndelegateCanceled

```solidity
event UndelegateCanceled(uint256 indexed id, address indexed delegator, address indexed validator, uint256 amount);
```

### Redelegated

```solidity
event Redelegated(address indexed delegator, address indexed from, address indexed to, uint256 amount);
```

### RewardsClaimed

```solidity
event RewardsClaimed(address indexed account, address indexed validator, uint256 amount);
```

### CommissionRewardsClaimed

```solidity
event CommissionRewardsClaimed(address indexed account, address indexed validator, uint256 amount);
```

### CommissionSet

```solidity
event CommissionSet(address indexed validator, uint16 commission);
```

### ValidatorRegistered

```solidity
event ValidatorRegistered(address indexed validator);
```

### ValidatorInfoSet

```solidity
event ValidatorInfoSet(address indexed validator);
```

## Structs
### ValidatorBasicInfo

```solidity
struct ValidatorBasicInfo {
    uint256 total_stake;
    uint256 commission_reward;
    uint16 commission;
    uint64 last_commission_change;
    uint16 undelegations_count;
    address owner;
    string description;
    string endpoint;
}
```

### ValidatorData

```solidity
struct ValidatorData {
    address account;
    ValidatorBasicInfo info;
}
```

### UndelegateRequest

```solidity
struct UndelegateRequest {
    uint256 eligible_block_num;
    uint256 amount;
}
```

### DelegatorInfo

```solidity
struct DelegatorInfo {
    uint256 stake;
    uint256 rewards;
}
```

### DelegationData

```solidity
struct DelegationData {
    address account;
    DelegatorInfo delegation;
}
```

### UndelegationData

```solidity
struct UndelegationData {
    uint256 stake;
    uint64 block;
    address validator;
    bool validator_exists;
}
```

### UndelegationV2Data

```solidity
struct UndelegationV2Data {
    UndelegationData undelegation_data;
    uint64 undelegation_id;
}
```

