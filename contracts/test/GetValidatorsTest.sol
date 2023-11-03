// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTestLotsOfValidators.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

contract GetValidatorsTest is Test, ManyValidatorsTestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function testGetLotsOfNodesForDelegation() public {
        // define value
        uint256 amount = 500000 ether;

        // call the function
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // check the length of the array
        assertEq(tentativeDelegations.length, 1, "Wrong length of array");

        // check if the value is the right one. It should be 500000 ether for the first validator
        assertEq(tentativeDelegations[0].amount, amount, "Wrong value");
    }

    function testFuzz_GetLotsOfNodesForDelegation(uint256 amount) public {
        // call the function
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // check the length of the array
        emit UpToThis(tentativeDelegations.length);
        uint256 validatorsLength = 0;
        if (amount / 80000000 ether >= validators.length) {
            validatorsLength = validators.length;
        } else if (amount % 80000000 ether == 0) {
            validatorsLength = amount / 80000000 ether;
        } else {
            validatorsLength = amount / 80000000 ether + 1;
        }
        assertEq(
            tentativeDelegations.length,
            validatorsLength,
            "Wrong length of array"
        );
    }
}
