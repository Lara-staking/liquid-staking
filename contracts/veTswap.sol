// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferFailed} from "@contracts/libs/SharedErrors.sol";

contract veTswap is ERC20, Ownable {
    ERC20 public tswap;

    constructor(address _tswap) ERC20("Vested Tswap", "veTSWAP") Ownable(msg.sender) {
        tswap = ERC20(_tswap);
        _mint(msg.sender, 1_000_000_000 ether);
    }

    function deposit(uint256 amount) external {
        bool success = tswap.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
