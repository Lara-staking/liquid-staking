// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LaraStaking} from "@contracts/LaraStaking.sol";

/// @custom:oz-upgrades-from LaraStaking
contract LaraStakeV2 is LaraStaking {
    uint256 public randomAddedSlot;

    function setRandomSlot(uint256 _randomAddedSlot) public {
        randomAddedSlot = _randomAddedSlot;
    }

    function getRandomSlot() public view returns (uint256) {
        return randomAddedSlot;
    }
}
