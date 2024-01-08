// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract stTARA is ERC20, Ownable {
    // Thrown when the user does not have sufficient allowance set for Tara to burn
    error InsufficientUserAllowanceForBurn(
        uint256 amount,
        uint256 senderBalance,
        uint256 protocolBalance
    );

    // Events
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    // Address of Lara protocol
    address public lara;

    constructor() ERC20("Staked TARA", "stTARA") Ownable(msg.sender) {}

    modifier onlyLara() {
        require(msg.sender == lara, "Only Lara can call this function");
        _;
    }

    function setLaraAddress(address _lara) external onlyOwner {
        lara = _lara;
    }

    function mint(address recipient, uint256 amount) external onlyLara {
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
