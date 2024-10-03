# CurrencyTransferLib
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/libs/CurrencyTransferLib.sol)

**Author:**
thirdweb


## State Variables
### NATIVE_TOKEN
*The address interpreted as native token of the chain.*


```solidity
address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


## Functions
### transferCurrency

*Transfers a given amount of currency.*


```solidity
function transferCurrency(address _currency, address _from, address _to, uint256 _amount) internal;
```

### transferCurrencyWithWrapper

*Transfers a given amount of currency. (With native token wrapping)*


```solidity
function transferCurrencyWithWrapper(
    address _currency,
    address _from,
    address _to,
    uint256 _amount,
    address _nativeTokenWrapper
) internal;
```

### safeTransferERC20

*Transfer `amount` of ERC20 token from `from` to `to`.*


```solidity
function safeTransferERC20(address _currency, address _from, address _to, uint256 _amount) internal;
```

### safeTransferNativeToken

*Transfers `amount` of native token to `to`.*


```solidity
function safeTransferNativeToken(address to, uint256 value) internal;
```

### safeTransferNativeTokenWithWrapper

*Transfers `amount` of native token to `to`. (With native token wrapping)*


```solidity
function safeTransferNativeTokenWithWrapper(address to, uint256 value, address _nativeTokenWrapper) internal;
```

## Errors
### CurrencyTransferLibMismatchedValue

```solidity
error CurrencyTransferLibMismatchedValue(uint256 expected, uint256 actual);
```

### CurrencyTransferLibFailedNativeTransfer

```solidity
error CurrencyTransferLibFailedNativeTransfer(address recipient, uint256 value);
```

