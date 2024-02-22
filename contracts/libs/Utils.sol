// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

library Utils {
    struct HolderData {
        address holder;
        uint256 amount;
    }

    struct Undelegation {
        address validator;
        uint256 amount;
    }

    function calculateSlice(
        uint256 amount,
        uint256 supply
    ) internal pure returns (uint256) {
        return (amount * 1e18) / supply; // The result is in 18 decimal format
    }

    function removeAddressFromArray(
        address[] storage array,
        address element
    ) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }
}
