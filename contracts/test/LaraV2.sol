// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Lara} from "../Lara.sol";

/// @custom:oz-upgrades-from Lara
contract LaraV2 is Lara {
    uint256 public randomAddedSlot;

    function setRandomSlot(uint256 _randomAddedSlot) public {
        randomAddedSlot = _randomAddedSlot;
    }

    function getRandomSlot() public view returns (uint256) {
        return randomAddedSlot;
    }
}
