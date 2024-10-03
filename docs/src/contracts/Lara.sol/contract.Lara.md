# Lara
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/Lara.sol)

**Inherits:**
OwnableUpgradeable, UUPSUpgradeable, [ILara](/contracts/interfaces/ILara.sol/interface.ILara.md), ReentrancyGuardUpgradeable

*This contract is used for staking and delegating tokens in the protocol.*


## State Variables
### protocolStartTimestamp
*Reference timestamp for computing systme health*


```solidity
uint256 public protocolStartTimestamp;
```


### lastSnapshotBlock
*Last snapshot timestamp*


```solidity
uint256 public lastSnapshotBlock;
```


### lastSnapshotId
*Last snapshot ID*


```solidity
uint256 public lastSnapshotId;
```


### lastRebalance
*Last rebalance timestamp*


```solidity
uint256 public lastRebalance;
```


### epochDuration
*Duration of an epoch in seconds, initially 1000 blocks*


```solidity
uint256 public epochDuration;
```


### maxValidatorStakeCapacity
*Maximum staking capacity for a validator*


```solidity
uint256 public maxValidatorStakeCapacity;
```


### minStakeAmount
*Minimum amount allowed for staking*


```solidity
uint256 public minStakeAmount;
```


### commission
*Protocol-level general commission percentage for rewards distribution*


```solidity
uint256 public commission;
```


### treasuryAddress
*Address of the protocol treasury*


```solidity
address public treasuryAddress;
```


### stTaraToken
*StTARA token contract*


```solidity
IstTara public stTaraToken;
```


### dposContract
*DPOS contract*


```solidity
DposInterface public dposContract;
```


### apyOracle
*APY oracle contract*


```solidity
IApyOracle public apyOracle;
```


### protocolTotalStakeAtValidator
*Mapping of the total stakes at a validator. Should be regularly updated
It should be a proxy of the DPOS contract delegations to a specific validator*


```solidity
mapping(address => uint256) public protocolTotalStakeAtValidator;
```


### protocolValidatorRatingAtDelegation
*Mapping of the validator rating at the time of delegation
It should be updated or set to zero when a validator is unregistered(has no delegation from Lara)*


```solidity
mapping(address => uint256) public protocolValidatorRatingAtDelegation;
```


### undelegated
*Mapping of the total undelegated amounts of a user*


```solidity
mapping(address => uint256) public undelegated;
```


### undelegations
*Mapping of individual undelegations by user
Should be a proxy to the undelegations in the DPOS contract, but we keep them in-memory for gas efficiency*


```solidity
mapping(address => mapping(uint64 => DposInterface.UndelegationV2Data)) public undelegations;
```


### commissionDiscounts
*Mapping of LARA staking commission discounts for staker addresses. Init values are 0 for all addresses, increasing linearly as per the
staking tokenomics. 1 unit means 1% increase to the epoch minted stTARA tokens.*


```solidity
mapping(address => uint32) public commissionDiscounts;
```


### rewardsPerSnapshot
*Mapping of the non-commission rewards per snapshot*


```solidity
mapping(uint256 => uint256) public rewardsPerSnapshot;
```


### stakerSnapshotClaimed
*Mapping of the staker snapshot claimed status*


```solidity
mapping(address => mapping(uint256 => bool)) public stakerSnapshotClaimed;
```


### __gap
*Gap for future upgrades. In case of new storage variables, they should be added before this gap and the array length should be reduced*


```solidity
uint256[49] __gap;
```


## Functions
### constructor


```solidity
constructor();
```

### initialize

*Initializer for the Lara contract.*


```solidity
function initialize(address _sttaraToken, address _dposContract, address _apyOracle, address _treasuryAddress)
    public
    initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_sttaraToken`|`address`|The address of the stTARA token contract.|
|`_dposContract`|`address`|The address of the DPOS contract.|
|`_apyOracle`|`address`|The address of the APY Oracle contract.|
|`_treasuryAddress`|`address`|The address of the treasury.|


### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### fallback

*Fallback function to receive Ether.*


```solidity
fallback() external payable;
```

### receive

*Function to receive Ether.*


```solidity
receive() external payable;
```

### isValidatorRegistered

Checks if a validator is registered in the protocol


```solidity
function isValidatorRegistered(address validator) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`validator`|`address`|the validator address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the validator is registered, false otherwise|


### setCommissionDiscounts

*Function to set the commission discounts*


```solidity
function setCommissionDiscounts(address staker, uint32 discount) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|the staker address|
|`discount`|`uint32`|the discount|


### setEpochDuration

Setter for epochDuration


```solidity
function setEpochDuration(uint256 _epochDuration) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_epochDuration`|`uint256`|new epoch duration (in seconds)|


### setCommission

*Function to set the commission*


```solidity
function setCommission(uint256 _commission) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_commission`|`uint256`|The new commission|


### setTreasuryAddress

*Function to set the treasury address*


```solidity
function setTreasuryAddress(address _treasuryAddress) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_treasuryAddress`|`address`|The new treasury address|


### setMaxValidatorStakeCapacity

*Function to set the maximum validator stake capacity*


```solidity
function setMaxValidatorStakeCapacity(uint256 _maxValidatorStakeCapacity) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_maxValidatorStakeCapacity`|`uint256`|The new maximum validator stake capacity|


### setMinStakeAmount

*Function to set the minimum stake amount*


```solidity
function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_minStakeAmount`|`uint256`|The new minimum stake amount|


### stake

Stake function
In the stake function, the user sends the amount of TARA tokens he wants to stake.
This method takes the payment and mints the stTARA tokens to the user.


```solidity
function stake(uint256 amount) public payable nonReentrant returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to stake|


### compound

*Function to compound the rewards into the staking contract*


```solidity
function compound(uint256 amount) public nonReentrant onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to compound|


### snapshot

method to create a protocol snapshot.
A protocol snapshot can be done once every epochDuration blocks.
The method will claim all rewards from the DPOS contract.


```solidity
function snapshot() external nonReentrant returns (uint256 id);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|the snapshot id of the made stTARA snapshot|


### distributeRewardsForSnapshot

*Function to distribute rewards for a snapshot*


```solidity
function distributeRewardsForSnapshot(address staker, uint256 snapshotId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`staker`|`address`|the staker address|
|`snapshotId`|`uint256`|the snapshot id|


### rebalance

Rebalance method to rebalance the protocol.
The method is intended to be called by anyone, at least every epochDuration blocks.
In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
The method will call the oracle to get the rebalance list and then redelegate the stake.


```solidity
function rebalance() public nonReentrant;
```

### confirmUndelegate

Confirm undelegate method to confirm the undelegation of a user from a certain validator.
Will fail if called before the undelegation period is over.


```solidity
function confirmUndelegate(uint64 id) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|


### batchConfirmUndelegate

Batch confirm undelegate method to confirm the undelegation of a user from a certain validator.
Will fail if called before the undelegation period is over.


```solidity
function batchConfirmUndelegate(uint64[] calldata ids) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ids`|`uint64[]`|the ids of the undelegations|


### cancelUndelegate

Cancel undelegate method to cancel the undelegation of a user from a certain validator.
The undelegated value will be returned to the origin validator.


```solidity
function cancelUndelegate(uint64 id) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint64`|the id of the undelegation|


### batchCancelUndelegate

Batch cancel undelegate method to cancel the undelegation of a user from a certain validator.
The undelegated value will be returned to the origin validator.


```solidity
function batchCancelUndelegate(uint64[] calldata ids) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ids`|`uint64[]`|the ids of the undelegations|


### requestUndelegate

Undelegates the amount from one or more validators.
The user needs to provide the amount of stTARA tokens he wants to undelegate. The protocol will burn them.


```solidity
function requestUndelegate(uint256 amount) public nonReentrant returns (uint64[] memory undelegation_ids);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of tokens to undelegate|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`undelegation_ids`|`uint64[]`|The ids of the undelegations done|


### _reDelegate

ReDelegate method to move stake from one validator to another inside the protocol.
The method is intended to be called by the protocol owner on a need basis.
In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.


```solidity
function _reDelegate(address from, address to, uint256 amount, uint256 rating) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|the validator from which to move stake|
|`to`|`address`|the validator to which to move stake|
|`amount`|`uint256`|the amount to move|
|`rating`|`uint256`||


### _delegateToValidators

Delegate function
In the delegate function, the caller can start the staking of any remaining balance in Lara towards the native DPOS contract.

Anyone can call, it will always delegate the given amount from Lara's balance


```solidity
function _delegateToValidators(uint256 amount) internal returns (uint256 remainingAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to delegate|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`remainingAmount`|`uint256`|the remaining amount that could not be delegated|


### _getValidatorsForAmount

Fetches the validators for the given amount


```solidity
function _getValidatorsForAmount(uint256 amount) internal returns (IApyOracle.TentativeDelegation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to fetch the validators for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`IApyOracle.TentativeDelegation[]`|the validators for the given amount|


### _findValidatorsWithDelegation

method to find the validators to delegate to


```solidity
function _findValidatorsWithDelegation(uint256 amount) internal view returns (address[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount to delegate|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|an array of validators to delegate amount of TARA to|


### _buildCurrentDelegationArray

method to build the current delegation array
Collects the current delegation data from the protocol and builds an array of TentativeDelegation structs


```solidity
function _buildCurrentDelegationArray() internal view returns (IApyOracle.TentativeDelegation[] memory);
```

### _getDelegationsFromDpos

method to get the delegations from the DPOS contract


```solidity
function _getDelegationsFromDpos() internal view returns (DposInterface.DelegationData[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`DposInterface.DelegationData[]`|the delegations from the DPOS contract|


### _syncDelegations

method to sync the delegations from the DPOS contract


```solidity
function _syncDelegations() internal;
```

