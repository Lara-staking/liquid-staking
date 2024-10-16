# LaraToken
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/LaraToken.sol)

**Inherits:**
ERC20, [ReentrancyGuard](/contracts/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)


## State Variables
### minSwapAmount

```solidity
uint256 public minSwapAmount;
```


### presaleStartBlock

```solidity
uint256 public presaleStartBlock;
```


### presaleEndBlock

```solidity
uint256 public presaleEndBlock;
```


### presaleBlockDuration

```solidity
uint256 public presaleBlockDuration;
```


### swapUpperLimit

```solidity
uint256 public swapUpperLimit;
```


### presaleRate

```solidity
uint256 public presaleRate;
```


### swapPeriod

```solidity
uint16 public swapPeriod;
```


### treasuryAddress

```solidity
address public treasuryAddress;
```


### presaleRunning

```solidity
bool public presaleRunning;
```


### presaleStartCount

```solidity
uint256 private presaleStartCount;
```


### presaleEndCount

```solidity
uint256 private presaleEndCount;
```


### lastSwapBlock

```solidity
mapping(address => uint256) public lastSwapBlock;
```


## Functions
### onlyOnce


```solidity
modifier onlyOnce();
```

### onlyOnceEnd


```solidity
modifier onlyOnceEnd();
```

### constructor


```solidity
constructor(address _treasury) ERC20("Lara", "LARA") ReentrancyGuard();
```

### receive


```solidity
receive() external payable;
```

### fallback


```solidity
fallback() external payable;
```

### startPresale

*Start the presale*


```solidity
function startPresale() external onlyOnce nonReentrant;
```

### endPresale

*End the presale*


```solidity
function endPresale() external onlyOnceEnd nonReentrant;
```

### swap

*Swap function*


```solidity
function swap() external payable nonReentrant;
```

## Events
### Swapped

```solidity
event Swapped(address indexed user, uint256 amount);
```

