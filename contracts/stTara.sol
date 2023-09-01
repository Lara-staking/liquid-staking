// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Import the ERC20 contract here

contract stTARA is ERC20 {
    address public owner;
    uint256 public minDelegateAmount = 1000 ether;

    constructor() ERC20("Staked TARA", "stTARA") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setMinDelegateAmount(uint256 amount) external onlyOwner {
        minDelegateAmount = amount;
    }

    function mint() external payable {
        uint256 amount = msg.value;
        require(
            amount >= minDelegateAmount,
            "Needs to be at least equal to minDelegateAmount"
        );
        _mint(msg.sender, amount);

        emit Minted(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient stTARA balance");

        // Burn stTARA tokens
        _burn(msg.sender, amount);

        // Transfer TARA tokens to the user
        payable(msg.sender).transfer(amount);

        emit Burned(msg.sender, amount);
    }

    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);
}
