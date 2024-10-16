# veLara
[Git Source](https://github.com-VargaElod23/Lara-staking/liquid-staking/blob/93907a3b8fb9a6839cf7eb3e681388f7e558b230/contracts/veLara.sol)

**Inherits:**
ERC20, Ownable


## State Variables
### lara

```solidity
ERC20 public lara;
```


## Functions
### constructor


```solidity
constructor(address _lara) ERC20("Vested Lara", "veLARA") Ownable(msg.sender);
```

### deposit


```solidity
function deposit(uint256 amount) external;
```

### burn


```solidity
function burn(uint256 amount) external;
```

