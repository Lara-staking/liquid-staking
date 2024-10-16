# LaraStaking
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/LaraStaking.sol)

**Inherits:**
Initializable, OwnableUpgradeable, UUPSUpgradeable, [Staking20Base](/contracts/Staking20Base.sol/abstract.Staking20Base.md), [ITokenStake](/contracts/interfaces/ITokenStake.sol/interface.ITokenStake.md)


## State Variables
### MODULE_TYPE

```solidity
bytes32 private constant MODULE_TYPE = bytes32("LaraStaking");
```


### VERSION

```solidity
uint256 private constant VERSION = 1;
```


### rewardToken
*ERC20 Reward Token address. See [_mintRewards](/contracts/LaraStaking.sol/contract.LaraStaking.md#_mintrewards) below.*


```solidity
address public rewardToken;
```


### rewardTokenBalance
*Total amount of reward tokens in the contract.*


```solidity
uint256 private rewardTokenBalance;
```


### MATURITY_BLOCK_COUNT

```solidity
uint256 public MATURITY_BLOCK_COUNT;
```


### CURRENT_CLAIM_ID

```solidity
uint64 public CURRENT_CLAIM_ID;
```


### claims

```solidity
mapping(address => mapping(uint64 => Claim)) public claims;
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

*Initializes the contract, like a constructor.*


```solidity
function initialize(
    address _rewardToken,
    address _stakingToken,
    uint80 _timeUnit,
    uint256 _rewardRatioNumerator,
    uint256 _rewardRatioDenominator,
    uint256 _newMaturityBlockCount
) public initializer;
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### _getTokenDecimals


```solidity
function _getTokenDecimals(address _token) internal view returns (uint16);
```

### contractType

*Returns the module type of the contract.*


```solidity
function contractType() external pure virtual returns (bytes32);
```

### contractVersion

*Returns the version of the contract.*


```solidity
function contractVersion() external pure virtual returns (uint8);
```

### receive

*Receive function to receive Ether.*


```solidity
receive() external payable;
```

### fallback

*Fallback function to receive Ether.*


```solidity
fallback() external payable;
```

### calculateRedeemableAmount


```solidity
function calculateRedeemableAmount(address user, uint64 claimId) public view returns (uint256);
```

### redeem


```solidity
function redeem(uint64 claimId) external nonReentrant;
```

### depositRewardTokens

*Admin deposits reward tokens.*


```solidity
function depositRewardTokens(uint256 _amount) external payable nonReentrant;
```

### withdrawRewardTokens

*Admin can withdraw excess reward tokens.*


```solidity
function withdrawRewardTokens(uint256 _amount) external nonReentrant;
```

### getRewardTokenBalance

View total rewards available in the staking contract.


```solidity
function getRewardTokenBalance() external view override returns (uint256);
```

### _mintRewards

*Mint/Transfer ERC20 rewards to the staker.*


```solidity
function _mintRewards(address _staker, uint256 _rewards) internal override;
```

### _canSetStakeConditions

*Returns whether staking related restrictions can be set in the given execution context.*


```solidity
function _canSetStakeConditions() internal view override returns (bool);
```

### _stakeMsgSender


```solidity
function _stakeMsgSender() internal view virtual override returns (address);
```

### _claimRewards


```solidity
function _claimRewards() internal override;
```

## Events
### Redeemed

```solidity
event Redeemed(address indexed user, uint64 indexed claimId, uint256 indexed amount);
```

## Structs
### Claim

```solidity
struct Claim {
    uint256 amount;
    uint64 blockNumber;
}
```

