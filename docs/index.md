# Solidity API

## ApyOracle

### constructor

```solidity
constructor(address dataFeed, address dpos) public
```

### maxValidatorStakeCapacity

```solidity
uint256 maxValidatorStakeCapacity
```

### nodeCount

```solidity
uint256 nodeCount
```

### nodesList

```solidity
address[] nodesList
```

### nodes

```solidity
mapping(address => struct IApyOracle.NodeData) nodes
```

### OnlyDataFeed

```solidity
modifier OnlyDataFeed()
```

### getNodeCount

```solidity
function getNodeCount() external view returns (uint256)
```

### getNodesForDelegation

```solidity
function getNodesForDelegation(uint256 amount) external view returns (struct IApyOracle.TentativeDelegation[])
```

Returns the list of nodes that can be delegated to, along with the amount that can be delegated to each node.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount to be delegated |

### updateNodeCount

```solidity
function updateNodeCount(uint256 count) external
```

### getDataFeedAddress

```solidity
function getDataFeedAddress() external view returns (address)
```

### getNodeData

```solidity
function getNodeData(address node) external view returns (struct IApyOracle.NodeData)
```

### updateNodeData

```solidity
function updateNodeData(address node, struct IApyOracle.NodeData data) external
```

## Lara

### protocolStartTimestamp

```solidity
uint256 protocolStartTimestamp
```

### epochDuration

```solidity
uint256 epochDuration
```

### maxValidatorStakeCapacity

```solidity
uint256 maxValidatorStakeCapacity
```

### minStakeAmount

```solidity
uint256 minStakeAmount
```

### stTaraToken

```solidity
contract IstTara stTaraToken
```

### dposContract

```solidity
contract DposInterface dposContract
```

### apyOracle

```solidity
contract IApyOracle apyOracle
```

### delegators

```solidity
address[] delegators
```

### validators

```solidity
address[] validators
```

### protocolTotalStakeAtValidator

```solidity
mapping(address => uint256) protocolTotalStakeAtValidator
```

### isCompounding

```solidity
mapping(address => bool) isCompounding
```

### stakedAmounts

```solidity
mapping(address => uint256) stakedAmounts
```

### delegatedAmounts

```solidity
mapping(address => uint256) delegatedAmounts
```

### claimableRewards

```solidity
mapping(address => uint256) claimableRewards
```

### undelegated

```solidity
mapping(address => uint256) undelegated
```

### lastEpochTotalDelegatedAmount

```solidity
uint256 lastEpochTotalDelegatedAmount
```

### isEpochRunning

```solidity
bool isEpochRunning
```

### constructor

```solidity
constructor(address _sttaraToken, address _dposContract, address _apyOracle) public
```

### fallback

```solidity
fallback() external payable
```

### receive

```solidity
receive() external payable
```

### onlyUser

```solidity
modifier onlyUser(address user)
```

### getDelegatorAtIndex

```solidity
function getDelegatorAtIndex(uint256 index) public view returns (address)
```

Getter for a certain delegator at a certain index

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | the index of the delegator |

### isValidatorRegistered

```solidity
function isValidatorRegistered(address validator) public view returns (bool)
```

Checks if a validator is registered in the protocol

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | the validator address |

### setEpochDuration

```solidity
function setEpochDuration(uint256 _epochDuration) public
```

Setter for epochDuration

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _epochDuration | uint256 | new epoch duration (in seconds) |

### setCompound

```solidity
function setCompound(address user, bool value) public
```

Setter for compounding

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| user | address | the user for which to set compounding |
| value | bool | the new value for compounding(T/F) |

### setMaxValidatorStakeCapacity

```solidity
function setMaxValidatorStakeCapacity(uint256 _maxValidatorStakeCapacity) external
```

onlyOwner Setter for maxValidatorStakeCapacity

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _maxValidatorStakeCapacity | uint256 | new maxValidatorStakeCapacity |

### setMinStakeAmount

```solidity
function setMinStakeAmount(uint256 _minStakeAmount) external
```

onlyOwner Setter for minStakeAmount

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minStakeAmount | uint256 | the new minStakeAmount |

### stake

```solidity
function stake(uint256 amount) public payable
```

Stake function
In the stake function, the user sends the amount of TARA tokens he wants to stake.
This method takes the payment and mints the stTARA tokens to the user.
The tokens are not DELEGATED INSTANTLY, but on the next epoch.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | the amount to stake |

### reDelegate

```solidity
function reDelegate(address from, address to, uint256 amount) public
```

ReDelegate method to move stake from one validator to another inside the protocol.
The method is intended to be called by the protocol owner on a need basis.
In this V0 there is no on-chain trigger or management function for this, will be triggere from outside.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | the validator from which to move stake |
| to | address | the validator to which to move stake |
| amount | uint256 | the amount to move |

### confirmUndelegate

```solidity
function confirmUndelegate(address validator, uint256 amount) public
```

Confirm undelegate method to confirm the undelegation of a user from a certain validator.
Will fail if called before the undelegation period is over.
msg.sender is the delegator

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | the validator from which to undelegate |
| amount | uint256 | the amount to undelegate |

### cancelUndelegate

```solidity
function cancelUndelegate(address validator, uint256 amount) public
```

Cancel undelegate method to cancel the undelegation of a user from a certain validator.
The undelegated value will be returned to the origin validator.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address | the validator from which to undelegate |
| amount | uint256 | the amount to undelegate |

### removeStake

```solidity
function removeStake(uint256 amount) public
```

Removes the stake of a user from the protocol.
reverts on missing approval for the amount.
The user needs to provide the amount of stTARA tokens he wants to get back as TARA

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | the amount of stTARA tokens to remove |

### requestUndelegate

```solidity
function requestUndelegate(uint256 amount) public
```

Undelegates the amount from one or more validators.
The user needs to provide the amount of stTARA tokens he wants to undelegate. The protocol will burn them.
reverts on missing approval for the amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | the amount of tokens to undelegate |

### claimRewards

```solidity
function claimRewards() public
```

Public method for claiming rewards.
The user can claim his rewards at any time but if there is an epoch running, he will only get the rewards from the last epoch.
Pays rewards in TARA.

### startEpoch

```solidity
function startEpoch() external
```

OnlyOwner method for starting a staking epoch.

### endEpoch

```solidity
function endEpoch() public
```

OnlyOwner method for ending a staking epoch.

### delegateToValidators

```solidity
function delegateToValidators(uint256 amount) internal returns (uint256 remainingAmount)
```

## NotAuthorized

```solidity
error NotAuthorized()
```

It is returned if the caller is not authorized

## RewardClaimFailed

```solidity
error RewardClaimFailed()
```

It is returned if reward claim from DPOS fails

## StakeAmountTooLow

```solidity
error StakeAmountTooLow(uint256 amount, uint256 minAmount)
```

## StakeValueTooLow

```solidity
error StakeValueTooLow(uint256 sentAmount, uint256 targetAmount)
```

## DelegationFailed

```solidity
error DelegationFailed(address validator, address delegator, uint256 amount)
```

It is returned if the delegation to a certain validator fails.

## IApyOracle

### NodeData

```solidity
struct NodeData {
  address account;
  uint16 rank;
  uint256 rating;
  uint16 apy;
  uint64 fromBlock;
  uint64 toBlock;
}
```

### TentativeDelegation

```solidity
struct TentativeDelegation {
  address validator;
  uint256 amount;
}
```

### NodeDataUpdated

```solidity
event NodeDataUpdated(address node, uint16 apy, uint256 pbftCount)
```

### getNodeCount

```solidity
function getNodeCount() external view returns (uint256)
```

### getNodesForDelegation

```solidity
function getNodesForDelegation(uint256 amount) external view returns (struct IApyOracle.TentativeDelegation[])
```

### updateNodeCount

```solidity
function updateNodeCount(uint256 count) external
```

### getNodeData

```solidity
function getNodeData(address node) external view returns (struct IApyOracle.NodeData)
```

### updateNodeData

```solidity
function updateNodeData(address node, struct IApyOracle.NodeData data) external
```

### getDataFeedAddress

```solidity
function getDataFeedAddress() external view returns (address)
```

## DposInterface

### Delegated

```solidity
event Delegated(address delegator, address validator, uint256 amount)
```

### Undelegated

```solidity
event Undelegated(address delegator, address validator, uint256 amount)
```

### UndelegateConfirmed

```solidity
event UndelegateConfirmed(address delegator, address validator, uint256 amount)
```

### UndelegateCanceled

```solidity
event UndelegateCanceled(address delegator, address validator, uint256 amount)
```

### Redelegated

```solidity
event Redelegated(address delegator, address from, address to, uint256 amount)
```

### RewardsClaimed

```solidity
event RewardsClaimed(address account, address validator, uint256 amount)
```

### CommissionRewardsClaimed

```solidity
event CommissionRewardsClaimed(address account, address validator, uint256 amount)
```

### CommissionSet

```solidity
event CommissionSet(address validator, uint16 commission)
```

### ValidatorRegistered

```solidity
event ValidatorRegistered(address validator)
```

### ValidatorInfoSet

```solidity
event ValidatorInfoSet(address validator)
```

### ValidatorBasicInfo

```solidity
struct ValidatorBasicInfo {
  uint256 total_stake;
  uint256 commission_reward;
  uint16 commission;
  uint64 last_commission_change;
  address owner;
  string description;
  string endpoint;
}
```

### ValidatorData

```solidity
struct ValidatorData {
  address account;
  struct DposInterface.ValidatorBasicInfo info;
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
  struct DposInterface.DelegatorInfo delegation;
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

### delegate

```solidity
function delegate(address validator) external payable
```

### undelegate

```solidity
function undelegate(address validator, uint256 amount) external
```

### confirmUndelegate

```solidity
function confirmUndelegate(address validator) external
```

### cancelUndelegate

```solidity
function cancelUndelegate(address validator) external
```

### reDelegate

```solidity
function reDelegate(address validator_from, address validator_to, uint256 amount) external
```

### claimRewards

```solidity
function claimRewards(address validator) external
```

### claimAllRewards

```solidity
function claimAllRewards(uint32 batch) external returns (bool end)
```

Claims staking rewards from all validators (limited by batch) that caller has delegated to

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| batch | uint32 | Batch number - there is a limit of 10 validators per batch that delegator can claim rewards from in single tranaction |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| end | bool | Flag if there are no more validators left that delegator can claim rewards from |

### claimCommissionRewards

```solidity
function claimCommissionRewards(address validator) external
```

### registerValidator

```solidity
function registerValidator(address validator, bytes proof, bytes vrf_key, uint16 commission, string description, string endpoint) external payable
```

### setValidatorInfo

```solidity
function setValidatorInfo(address validator, string description, string endpoint) external
```

Sets some of the static validator details.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| validator | address |  |
| description | string | New description (e.g name, short purpose description, etc...) |
| endpoint | string | New endpoint, might be a validator's website |

### setCommission

```solidity
function setCommission(address validator, uint16 commission) external
```

### isValidatorEligible

```solidity
function isValidatorEligible(address validator) external view returns (bool)
```

### getTotalEligibleVotesCount

```solidity
function getTotalEligibleVotesCount() external view returns (uint64)
```

### getValidatorEligibleVotesCount

```solidity
function getValidatorEligibleVotesCount(address validator) external view returns (uint64)
```

### getValidator

```solidity
function getValidator(address validator) external view returns (struct DposInterface.ValidatorBasicInfo validator_info)
```

### getValidators

```solidity
function getValidators(uint32 batch) external view returns (struct DposInterface.ValidatorData[] validators, bool end)
```

### getValidatorsFor

```solidity
function getValidatorsFor(address owner, uint32 batch) external view returns (struct DposInterface.ValidatorData[] validators, bool end)
```

Returns list of validators owned by an address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | Owner address |
| batch | uint32 | Batch number to be fetched. If the list is too big it cannot return all validators in one call. Instead, users are fetching batches of 100 account at a time |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validators | struct DposInterface.ValidatorData[] | Batch of N validators basic info |
| end | bool | Flag if there are no more accounts left. To get all accounts, caller should fetch all batches until he sees end == true |

### getTotalDelegation

```solidity
function getTotalDelegation(address delegator) external view returns (uint256 total_delegation)
```

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delegator | address | delegator account address |

### getDelegations

```solidity
function getDelegations(address delegator, uint32 batch) external view returns (struct DposInterface.DelegationData[] delegations, bool end)
```

Returns list of delegations for specified delegator - which validators delegator delegated to

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delegator | address | delegator account address |
| batch | uint32 | Batch number to be fetched. If the list is too big it cannot return all delegations in one call. Instead, users are fetching batches of 50 delegations at a time |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| delegations | struct DposInterface.DelegationData[] | Batch of N delegations |
| end | bool | Flag if there are no more delegations left. To get all delegations, caller should fetch all batches until he sees end == true |

### getUndelegations

```solidity
function getUndelegations(address delegator, uint32 batch) external view returns (struct DposInterface.UndelegationData[] undelegations, bool end)
```

Returns list of undelegations for specified delegator

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| delegator | address | delegator account address |
| batch | uint32 | Batch number to be fetched. If the list is too big it cannot return all undelegations in one call. Instead, users are fetching batches of 50 undelegations at a time |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| undelegations | struct DposInterface.UndelegationData[] | Batch of N undelegations |
| end | bool | Flag if there are no more undelegations left. To get all undelegations, caller should fetch all batches until he sees end == true |

## ILara

### Staked

```solidity
event Staked(address user, uint256 amount)
```

### Delegated

```solidity
event Delegated(address user, uint256 amount)
```

### EpochStarted

```solidity
event EpochStarted(uint256 totalEpochDelegation, uint256 timestamp)
```

### RewardsClaimed

```solidity
event RewardsClaimed(address user, uint256 amount, uint256 timestamp)
```

### EpochEnded

```solidity
event EpochEnded(uint256 totalEpochDelegation, uint256 totalEpochReward, uint256 timestamp)
```

### Undelegated

```solidity
event Undelegated(address user, address validator, uint256 amount)
```

### TaraSent

```solidity
event TaraSent(address user, uint256 amount, uint256 blockNumber)
```

### StakeRemoved

```solidity
event StakeRemoved(address user, uint256 amount)
```

### getDelegatorAtIndex

```solidity
function getDelegatorAtIndex(uint256 index) external view returns (address)
```

### isValidatorRegistered

```solidity
function isValidatorRegistered(address validator) external view returns (bool)
```

### setEpochDuration

```solidity
function setEpochDuration(uint256 _epochDuration) external
```

### setCompound

```solidity
function setCompound(address user, bool value) external
```

### setMaxValidatorStakeCapacity

```solidity
function setMaxValidatorStakeCapacity(uint256 _maxValidatorStakeCapacity) external
```

### setMinStakeAmount

```solidity
function setMinStakeAmount(uint256 _minStakeAmount) external
```

### stake

```solidity
function stake(uint256 amount) external payable
```

### removeStake

```solidity
function removeStake(uint256 amount) external
```

### reDelegate

```solidity
function reDelegate(address from, address to, uint256 amount) external
```

### confirmUndelegate

```solidity
function confirmUndelegate(address validator, uint256 amount) external
```

### cancelUndelegate

```solidity
function cancelUndelegate(address validator, uint256 amount) external
```

### requestUndelegate

```solidity
function requestUndelegate(uint256 amount) external
```

### claimRewards

```solidity
function claimRewards() external
```

### startEpoch

```solidity
function startEpoch() external
```

### endEpoch

```solidity
function endEpoch() external
```

## INodeContinuityOracle

### NodeStats

```solidity
struct NodeStats {
  uint64 dagsCount;
  uint64 lastDagTimestamp;
  uint64 lastPbftTimestamp;
  uint64 lastTransactionTimestamp;
  uint64 pbftCount;
  uint64 transactionsCount;
}
```

### NodeDataUpdated

```solidity
event NodeDataUpdated(address node, uint64 timestamp, uint256 pbftCount)
```

### getNodeUpdateTimestamps

```solidity
function getNodeUpdateTimestamps(address node) external view returns (uint64[] timestamps)
```

### getNodeStatsFrom

```solidity
function getNodeStatsFrom(uint64 timestamp) external view returns (struct INodeContinuityOracle.NodeStats)
```

### updateNodeStats

```solidity
function updateNodeStats(address node, uint64 timestamp, struct INodeContinuityOracle.NodeStats stats) external
```

### getDataFeedAddress

```solidity
function getDataFeedAddress() external view returns (address)
```

## IstTara

### mint

```solidity
function mint(address recipient, uint256 amount) external payable
```

### burn

```solidity
function burn(address user, uint256 amount) external
```

## MockDpos

### Undelegation

```solidity
struct Undelegation {
  address delegator;
  uint256 amount;
  uint256 blockNumberClaimable;
}
```

### validators

```solidity
mapping(address => struct MockIDPOS.ValidatorData) validators
```

### validatorDatas

```solidity
struct MockIDPOS.ValidatorData[] validatorDatas
```

### undelegations

```solidity
mapping(address => struct MockDpos.Undelegation) undelegations
```

### UNDELEGATION_DELAY_BLOCKS

```solidity
uint256 UNDELEGATION_DELAY_BLOCKS
```

### constructor

```solidity
constructor(address[] _internalValidators) public payable
```

### isValidatorRegistered

```solidity
function isValidatorRegistered(address validator) external view returns (bool)
```

### getValidator

```solidity
function getValidator(address validator) external view returns (struct MockIDPOS.ValidatorBasicInfo)
```

### getValidators

```solidity
function getValidators(uint32 batch) external view returns (struct MockIDPOS.ValidatorData[] validatorsOut, bool end)
```

### getValidatorsFor

```solidity
function getValidatorsFor(address owner, uint32 batch) external view returns (struct MockIDPOS.ValidatorData[] validatorsOut, bool end)
```

### delegate

```solidity
function delegate(address validator) external payable
```

### registerValidator

```solidity
function registerValidator(address validator, bytes proof, bytes vrf_key, uint16 commission, string description, string endpoint) external payable
```

### undelegate

```solidity
function undelegate(address validator, uint256 amount) external
```

### DelegationRewards

```solidity
event DelegationRewards(uint256 totalStakes, uint256 totalRewards)
```

### claimAllRewards

```solidity
function claimAllRewards(uint32 batch) external returns (bool end)
```

### reDelegate

```solidity
function reDelegate(address validator_from, address validator_to, uint256 amount) external
```

### confirmUndelegate

```solidity
function confirmUndelegate(address validator) external
```

### CallerCheck

```solidity
event CallerCheck(address CallerCheck)
```

### cancelUndelegate

```solidity
function cancelUndelegate(address validator) external
```

## MockIDPOS

### Delegated

```solidity
event Delegated(address delegator, address validator, uint256 amount)
```

### Undelegated

```solidity
event Undelegated(address delegator, address validator, uint256 amount)
```

### UndelegateConfirmed

```solidity
event UndelegateConfirmed(address delegator, address validator, uint256 amount)
```

### UndelegateCanceled

```solidity
event UndelegateCanceled(address delegator, address validator, uint256 amount)
```

### RewardsClaimed

```solidity
event RewardsClaimed(address account, address validator)
```

### CommissionRewardsClaimed

```solidity
event CommissionRewardsClaimed(address account, address validator)
```

### CommissionSet

```solidity
event CommissionSet(address validator, uint16 comission)
```

### ValidatorRegistered

```solidity
event ValidatorRegistered(address validator)
```

### ValidatorInfoSet

```solidity
event ValidatorInfoSet(address validator)
```

### Redelegated

```solidity
event Redelegated(address delegator, address from, address to, uint256 amount)
```

### ValidatorBasicInfo

```solidity
struct ValidatorBasicInfo {
  uint256 total_stake;
  uint256 commission_reward;
  uint16 commission;
  uint64 last_commission_change;
  address owner;
  string description;
  string endpoint;
}
```

### ValidatorData

```solidity
struct ValidatorData {
  address account;
  struct MockIDPOS.ValidatorBasicInfo info;
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
  struct MockIDPOS.DelegatorInfo delegation;
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

### delegate

```solidity
function delegate(address validator) external payable
```

### registerValidator

```solidity
function registerValidator(address validator, bytes proof, bytes vrf_key, uint16 commission, string description, string endpoint) external payable
```

### getValidator

```solidity
function getValidator(address validator) external view returns (struct MockIDPOS.ValidatorBasicInfo validator_info)
```

### undelegate

```solidity
function undelegate(address validator, uint256 amount) external
```

### getValidators

```solidity
function getValidators(uint32 batch) external view returns (struct MockIDPOS.ValidatorData[] validators, bool end)
```

### getValidatorsFor

```solidity
function getValidatorsFor(address owner, uint32 batch) external view returns (struct MockIDPOS.ValidatorData[] validators, bool end)
```

### claimAllRewards

```solidity
function claimAllRewards(uint32 batch) external returns (bool end)
```

### reDelegate

```solidity
function reDelegate(address validator_from, address validator_to, uint256 amount) external
```

### confirmUndelegate

```solidity
function confirmUndelegate(address validator) external
```

### cancelUndelegate

```solidity
function cancelUndelegate(address validator) external
```

## stTARA

### DepositAmountTooLow

```solidity
error DepositAmountTooLow(uint256 amount, uint256 minAmount)
```

### MintValueTooLow

```solidity
error MintValueTooLow(uint256 sentAmount, uint256 minAmount)
```

### WrongBurnAddress

```solidity
error WrongBurnAddress(address wrongAddress)
```

### InsufficientUserAllowanceForBurn

```solidity
error InsufficientUserAllowanceForBurn(uint256 amount, uint256 senderBalance, uint256 protocolBalance)
```

### InsufficientProtocolBalanceForBurn

```solidity
error InsufficientProtocolBalanceForBurn(uint256 amount, uint256 protocolBalance)
```

### Minted

```solidity
event Minted(address user, uint256 amount)
```

### Burned

```solidity
event Burned(address user, uint256 amount)
```

### minDepositAmount

```solidity
uint256 minDepositAmount
```

### lara

```solidity
address lara
```

### constructor

```solidity
constructor() public
```

### onlyLara

```solidity
modifier onlyLara()
```

### setMinDepositAmount

```solidity
function setMinDepositAmount(uint256 _minDepositAmount) external
```

### setLaraAddress

```solidity
function setLaraAddress(address _lara) external
```

### mint

```solidity
function mint(address recipient, uint256 amount) external
```

### burn

```solidity
function burn(address user, uint256 amount) external
```

## CompoundTest

### staker0

```solidity
address staker0
```

### staker1

```solidity
address staker1
```

### staker2

```solidity
address staker2
```

### MAX_VALIDATOR_STAKE_CAPACITY

```solidity
uint256 MAX_VALIDATOR_STAKE_CAPACITY
```

### setUp

```solidity
function setUp() public
```

### getTotalDposStake

```solidity
function getTotalDposStake() public view returns (uint256)
```

### testFuzz_testStakeToSingleValidator

```solidity
function testFuzz_testStakeToSingleValidator(uint256 amount) public
```

### testStakeToMultipleValidators

```solidity
function testStakeToMultipleValidators() public
```

### calculateExpectedRewardForUser

```solidity
function calculateExpectedRewardForUser(address staker) public view returns (uint256)
```

### test_launchNextEpoch

```solidity
function test_launchNextEpoch() public
```

## DelegateTest

### setUp

```solidity
function setUp() public
```

### testGetNodesForDelegation

```solidity
function testGetNodesForDelegation() public
```

### testFuzz_GetNodesForDelegation

```solidity
function testFuzz_GetNodesForDelegation(uint256 amount) public
```

### testFailStakeAmountTooLow

```solidity
function testFailStakeAmountTooLow() public
```

### testFailStakeValueTooLow

```solidity
function testFailStakeValueTooLow() public
```

### firstAmountToStake

```solidity
uint256 firstAmountToStake
```

### testFuzz_testStakeToSingleValidator

```solidity
function testFuzz_testStakeToSingleValidator(uint256 amount) public
```

### DelegationReward

```solidity
event DelegationReward(uint256 totalStakes, uint256 totalRewards)
```

### testStakeToMultipleValidators

```solidity
function testStakeToMultipleValidators() public
```

### testFailValidatorsFull

```solidity
function testFailValidatorsFull() public
```

## GetValidatorsTest

### setUp

```solidity
function setUp() public
```

### testGetLotsOfNodesForDelegation

```solidity
function testGetLotsOfNodesForDelegation() public
```

### testFuzz_GetLotsOfNodesForDelegation

```solidity
function testFuzz_GetLotsOfNodesForDelegation(uint256 amount) public
```

## ReDelegateTest

### setUp

```solidity
function setUp() public
```

### testFuzz_testRedelegateStakeToSingleValidator

```solidity
function testFuzz_testRedelegateStakeToSingleValidator(uint256 amount) public
```

### testFuzz_testRedelegateStakeToMultipleValidators

```solidity
function testFuzz_testRedelegateStakeToMultipleValidators(uint256 amount) public
```

## TestSetup

### lara

```solidity
contract Lara lara
```

### mockApyOracle

```solidity
contract ApyOracle mockApyOracle
```

### mockDpos

```solidity
contract MockDpos mockDpos
```

### stTaraToken

```solidity
contract stTARA stTaraToken
```

### numValidators

```solidity
uint16 numValidators
```

### validators

```solidity
address[] validators
```

### setupValidators

```solidity
function setupValidators() public
```

### setupApyOracle

```solidity
function setupApyOracle() public
```

### setupLara

```solidity
function setupLara() public
```

### checkValidatorTotalStakesAreZero

```solidity
function checkValidatorTotalStakesAreZero() public
```

### findValidatorWithStake

```solidity
function findValidatorWithStake(uint256 stake) public view returns (address)
```

## ManyValidatorsTestSetup

### lara

```solidity
contract Lara lara
```

### mockApyOracle

```solidity
contract ApyOracle mockApyOracle
```

### mockDpos

```solidity
contract MockDpos mockDpos
```

### stTaraToken

```solidity
contract stTARA stTaraToken
```

### numValidators

```solidity
uint16 numValidators
```

### validators

```solidity
address[] validators
```

### UpToThis

```solidity
event UpToThis(uint256 value)
```

### setupValidators

```solidity
function setupValidators() public
```

### setupApyOracle

```solidity
function setupApyOracle() public
```

### setupLara

```solidity
function setupLara() public
```

### checkValidatorTotalStakesAreZero

```solidity
function checkValidatorTotalStakesAreZero() public
```

### findValidatorWithStake

```solidity
function findValidatorWithStake(uint256 stake) public view returns (address)
```

## LaraSetterTest

### delegators

```solidity
address[] delegators
```

### setUp

```solidity
function setUp() public
```

### testFuzz_setMaxValdiatorStakeCapacity

```solidity
function testFuzz_setMaxValdiatorStakeCapacity(address setter) public
```

### testFuzz_setMinStakeAmount

```solidity
function testFuzz_setMinStakeAmount(address setter) public
```

## UndelegateTest

### setUp

```solidity
function setUp() public
```

### fallback

```solidity
fallback() external payable
```

### receive

```solidity
receive() external payable
```

### testFuzz_testStakeAndRemoveStake

```solidity
function testFuzz_testStakeAndRemoveStake(uint256 amount) public
```

### invariant_testStakeAndRemoveStake

```solidity
function invariant_testStakeAndRemoveStake() public
```

### testFuzz_failsToUndelegateDuringEpoch

```solidity
function testFuzz_failsToUndelegateDuringEpoch(uint256 amount) public
```

### testFuzz_failsToUndelegateWithoutApproval

```solidity
function testFuzz_failsToUndelegateWithoutApproval(uint256 amount) public
```

### testFuzz_failsToUndelegateForSomeoneElse

```solidity
function testFuzz_failsToUndelegateForSomeoneElse(uint256 amount) public
```

### testFuzz_singleStakeAndUnstake

```solidity
function testFuzz_singleStakeAndUnstake(uint256 amount) public
```

### invariant_testFuzz_singleStakeAndUnstake

```solidity
function invariant_testFuzz_singleStakeAndUnstake() public
```

## NodeContinuityOracle

### constructor

```solidity
constructor(address dataFeed) public
```

### nodeStatsUpdateTimestamps

```solidity
mapping(address => uint64[]) nodeStatsUpdateTimestamps
```

### nodeStats

```solidity
mapping(uint64 => struct INodeContinuityOracle.NodeStats) nodeStats
```

### OnlyDataFeed

```solidity
modifier OnlyDataFeed()
```

### getDataFeedAddress

```solidity
function getDataFeedAddress() external view returns (address)
```

### updateNodeStats

```solidity
function updateNodeStats(address node, uint64 timestamp, struct INodeContinuityOracle.NodeStats data) external
```

### getNodeUpdateTimestamps

```solidity
function getNodeUpdateTimestamps(address node) external view returns (uint64[] timestamps)
```

### getNodeStatsFrom

```solidity
function getNodeStatsFrom(uint64 timestamp) external view returns (struct INodeContinuityOracle.NodeStats)
```

