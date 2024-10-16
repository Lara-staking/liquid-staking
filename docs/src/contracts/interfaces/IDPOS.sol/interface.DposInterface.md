# DposInterface
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/IDPOS.sol)


## Functions
### delegate


```solidity
function delegate(address validator) external payable;
```

### undelegate


```solidity
function undelegate(address validator, uint256 amount) external;
```

### undelegateV2


```solidity
function undelegateV2(address validator, uint256 amount) external returns (uint64 undelegation_id);
```

### confirmUndelegate


```solidity
function confirmUndelegate(address validator) external;
```

### confirmUndelegateV2


```solidity
function confirmUndelegateV2(address validator, uint64 undelegation_id) external;
```

### cancelUndelegate


```solidity
function cancelUndelegate(address validator) external;
```

### cancelUndelegateV2


```solidity
function cancelUndelegateV2(address validator, uint64 undelegation_id) external;
```

### reDelegate


```solidity
function reDelegate(address validator_from, address validator_to, uint256 amount) external;
```

### claimRewards


```solidity
function claimRewards(address validator) external;
```

### claimAllRewards

Claims staking rewards from all validators (limited by max dag block gas limit) that caller has delegated to


```solidity
function claimAllRewards() external;
```

### claimCommissionRewards


```solidity
function claimCommissionRewards(address validator) external;
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

### setValidatorInfo

Sets some of the static validator details.


```solidity
function setValidatorInfo(address validator, string calldata description, string calldata endpoint) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`validator`|`address`||
|`description`|`string`|  New description (e.g name, short purpose description, etc...)|
|`endpoint`|`string`|     New endpoint, might be a validator's website|


### setCommission


```solidity
function setCommission(address validator, uint16 commission) external;
```

### isValidatorEligible


```solidity
function isValidatorEligible(address validator) external view returns (bool);
```

### getTotalEligibleVotesCount


```solidity
function getTotalEligibleVotesCount() external view returns (uint64);
```

### getValidatorEligibleVotesCount


```solidity
function getValidatorEligibleVotesCount(address validator) external view returns (uint64);
```

### getValidator


```solidity
function getValidator(address validator) external view returns (ValidatorBasicInfo memory validator_info);
```

### getValidators


```solidity
function getValidators(uint32 batch) external view returns (ValidatorData[] memory validators, bool end);
```

### getValidatorsFor

Returns list of validators owned by an address


```solidity
function getValidatorsFor(address owner, uint32 batch)
    external
    view
    returns (ValidatorData[] memory validators, bool end);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|       Owner address|
|`batch`|`uint32`|       Batch number to be fetched. If the list is too big it cannot return all validators in one call. Instead, users are fetching batches of 100 account at a time|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`validators`|`ValidatorData[]`| Batch of N validators basic info|
|`end`|`bool`|        Flag if there are no more accounts left. To get all accounts, caller should fetch all batches until he sees end == true|


### getTotalDelegation

Returns total delegation for specified delegator


```solidity
function getTotalDelegation(address delegator) external view returns (uint256 total_delegation);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|Delegator account address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`total_delegation`|`uint256`|amount that was delegated|


### getDelegations

Returns list of delegations for specified delegator - which validators delegator delegated to


```solidity
function getDelegations(address delegator, uint32 batch)
    external
    view
    returns (DelegationData[] memory delegations, bool end);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|    delegator account address|
|`batch`|`uint32`|        Batch number to be fetched. If the list is too big it cannot return all delegations in one call. Instead, users are fetching batches of 50 delegations at a time|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`delegations`|`DelegationData[]`| Batch of N delegations|
|`end`|`bool`|         Flag if there are no more delegations left. To get all delegations, caller should fetch all batches until he sees end == true|


### getUndelegations

Returns list of undelegations for specified delegator


```solidity
function getUndelegations(address delegator, uint32 batch)
    external
    view
    returns (UndelegationData[] memory undelegations, bool end);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|      delegator account address|
|`batch`|`uint32`|          Batch number to be fetched. If the list is too big it cannot return all undelegations in one call. Instead, users are fetching batches of 50 undelegations at a time|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`undelegations`|`UndelegationData[]`| Batch of N undelegations|
|`end`|`bool`|           Flag if there are no more undelegations left. To get all undelegations, caller should fetch all batches until he sees end == true|


### getUndelegationsV2

Returns list of V2 undelegations for specified delegator


```solidity
function getUndelegationsV2(address delegator, uint32 batch)
    external
    view
    returns (UndelegationV2Data[] memory undelegations_v2, bool end);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|      delegator account address|
|`batch`|`uint32`|          Batch number to be fetched. If the list is too big it cannot return all undelegations in one call. Instead, users are fetching batches of 50 undelegations at a time|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`undelegations_v2`|`UndelegationV2Data[]`| Batch of N undelegations|
|`end`|`bool`|           Flag if there are no more undelegations left. To get all undelegations, caller should fetch all batches until he sees end == true|


### getUndelegationV2

Returns V2 undelegation for specified delegator, validator & and undelegation_id


```solidity
function getUndelegationV2(address delegator, address validator, uint64 undelegation_id)
    external
    view
    returns (UndelegationV2Data memory undelegation_v2);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`delegator`|`address`|       delegator account address|
|`validator`|`address`|       validator account address|
|`undelegation_id`|`uint64`| undelegation id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`undelegation_v2`|`UndelegationV2Data`|undelegation_v2|


## Events
### Delegated

```solidity
event Delegated(address indexed delegator, address indexed validator, uint256 amount);
```

### Undelegated

```solidity
event Undelegated(address indexed delegator, address indexed validator, uint256 amount);
```

### UndelegateConfirmed

```solidity
event UndelegateConfirmed(address indexed delegator, address indexed validator, uint256 amount);
```

### UndelegateCanceled

```solidity
event UndelegateCanceled(address indexed delegator, address indexed validator, uint256 amount);
```

### UndelegatedV2

```solidity
event UndelegatedV2(
    address indexed delegator, address indexed validator, uint64 indexed undelegation_id, uint256 amount
);
```

### UndelegateConfirmedV2

```solidity
event UndelegateConfirmedV2(
    address indexed delegator, address indexed validator, uint64 indexed undelegation_id, uint256 amount
);
```

### UndelegateCanceledV2

```solidity
event UndelegateCanceledV2(
    address indexed delegator, address indexed validator, uint64 indexed undelegation_id, uint256 amount
);
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

