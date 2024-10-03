# ITokenStake
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/interfaces/ITokenStake.sol)

Thirdweb's TokenStake smart contract allows users to stake their ERC-20 Tokens
and earn rewards in form of a different ERC-20 token.
note:
- Reward token and staking token can't be changed after deployment.
Reward token contract can't be the same as the staking token contract.
- ERC20 tokens from only the specified contract can be staked.
- All token transfers require approval on their respective token-contracts.
- Admin must deposit reward tokens using the `depositRewardTokens` function only.
Any direct transfers may cause unintended consequences, such as locking of tokens.
- Users must stake tokens using the `stake` function only.
Any direct transfers may cause unintended consequences, such as locking of tokens.


## Functions
### depositRewardTokens

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) deposit reward-tokens.
note: Tokens should be approved on the reward-token contract before depositing.


```solidity
function depositRewardTokens(uint256 _amount) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|    Amount of tokens to deposit.|


### withdrawRewardTokens

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) withdraw reward-tokens.
Useful for removing excess balance, thus preventing locking of tokens.


```solidity
function withdrawRewardTokens(uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|    Amount of tokens to withdraw.|


## Events
### RewardTokensWithdrawnByAdmin
*Emitted when contract admin withdraws reward tokens.*


```solidity
event RewardTokensWithdrawnByAdmin(uint256 indexed _amount);
```

### RewardTokensDepositedByAdmin
*Emitted when contract admin deposits reward tokens.*


```solidity
event RewardTokensDepositedByAdmin(uint256 indexed _amount);
```

