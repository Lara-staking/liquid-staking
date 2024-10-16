// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TransferFailed} from "@contracts/libs/SharedErrors.sol";

contract veLara is ERC20, Ownable {
    ERC20 public lara;

    constructor(address _lara) ERC20("Vested Lara", "veLARA") Ownable(msg.sender) {
        lara = ERC20(_lara);
        _mint(msg.sender, 1000000 ether);
    }

    function deposit(uint256 amount) external {
        bool success = lara.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
