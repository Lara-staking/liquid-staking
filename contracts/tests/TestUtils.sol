// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/LaraErrors.sol";

abstract contract TestUtils {
    Lara lara;

    function getDelegationTotal(
        address delegator
    ) public view returns (uint256) {
        ILara.IndividualDelegation[] memory delegatorData = lara
            .getIndividualDelegations(delegator);

        uint256 totalDelegated = 0;
        for (uint256 i = 0; i < delegatorData.length; i++) {
            totalDelegated += delegatorData[i].amount;
        }
        return totalDelegated;
    }
}
