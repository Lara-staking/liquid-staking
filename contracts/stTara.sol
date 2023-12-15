// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract stTARA is ERC20, Ownable {
    // Thrown when the amount sent for minting is lower than min allowed
    error DepositAmountTooLow(uint256 amount, uint256 minAmount);

    // Thrown when the value sent for the mint by an user is lower than min allowed
    error MintValueTooLow(uint256 sentAmount, uint256 minAmount);

    // Thrown when the burn caller is not the user or the lara protocol
    error WrongBurnAddress(address wrongAddress);

    // Thrown when the user does not have sufficient allowance set for Tara to burn
    error InsufficientUserAllowanceForBurn(
        uint256 amount,
        uint256 senderBalance,
        uint256 protocolBalance
    );

    // Thrown when Lara burns too many tokens for an user
    error InsufficientProtocolBalanceForBurn(
        uint256 amount,
        uint256 protocolBalance
    );

    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    // State variables
    uint256 public minDepositAmount = 1000 ether;

    // Address of Lara protocol
    address public lara;

    constructor() ERC20("Staked TARA", "stTARA") Ownable(msg.sender) {}

    modifier onlyLara() {
        require(msg.sender == lara, "Only Lara can call this function");
        _;
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    function setLaraAddress(address _lara) external onlyOwner {
        lara = _lara;
    }

    function mint(address recipient, uint256 amount) external onlyLara {
        if (amount < minDepositAmount) {
            revert DepositAmountTooLow(amount, minDepositAmount);
        }
        super._mint(recipient, amount);

        emit Minted(recipient, amount);
    }

    function burn(address user, uint256 amount) external onlyLara {
        if (msg.sender != lara) {
            // Check if the amount is approved for lara to burn
            if (amount > allowance(user, lara))
                revert InsufficientUserAllowanceForBurn(
                    amount,
                    balanceOf(user),
                    allowance(user, lara)
                );
        }
        // Burn stTARA tokens
        super._burn(user, amount);

        emit Burned(user, amount);
    }
}
