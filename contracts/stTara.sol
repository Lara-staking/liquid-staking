// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract stTARA is ERC20, Ownable {
    // Errors
    error DepositAmountTooLow(uint256 amount, uint256 minAmount);
    error InsufficientBalanceForBurn(uint256 amount, uint256 senderBalance);

    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    // State variables
    uint256 public minDepositAmount = 1000 ether;

    constructor() ERC20("Staked TARA", "stTARA") {}

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    function mint() external payable {
        uint256 amount = msg.value;
        if(amount < minDepositAmount)
            revert DepositAmountTooLow(amount, minDepositAmount);
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        if(balanceOf(msg.sender) < amount) 
            revert InsufficientBalanceForBurn(amount, balanceOf(msg.sender));

        // Burn stTARA tokens
        _burn(msg.sender, amount);

        // Transfer TARA tokens to the user
        payable(msg.sender).transfer(amount);

        emit Burned(msg.sender, amount);
    }
}
