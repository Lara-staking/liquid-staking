// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "@contracts/interfaces/IApyOracle.sol";
import {Lara} from "@contracts/Lara.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";
import {MockDpos} from "@contracts/mocks/MockDpos.sol";
import {StakedNativeAsset} from "@contracts/StakedNativeAsset.sol";
import {ManyValidatorsTestSetup} from "@contracts/test/SetUpLotsOfValidators.t.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "@contracts/libs/SharedErrors.sol";

contract GetValidatorsTest is Test, ManyValidatorsTestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function test_revertOnNotLara() public {
        // call the function
        vm.expectRevert("ApyOracle: caller is not Lara");
        mockApyOracle.getNodesForDelegation(100000 ether);
    }

    event LaraAddress(address lara);

    function test_GetLotsOfNodesForDelegation() public {
        // define value
        uint256 amount = 500000 ether;

        address laraAddress = mockApyOracle.lara();
        emit LaraAddress(laraAddress);
        vm.prank(address(laraAddress));
        // call the function
        IApyOracle.TentativeDelegation[] memory tentativeDelegations = mockApyOracle.getNodesForDelegation(amount);

        // check the length of the array
        assertEq(tentativeDelegations.length, 1, "Wrong length of array");

        // check if the value is the right one. It should be 500000 ether for the first validator
        assertEq(tentativeDelegations[0].amount, amount, "Wrong value");
    }

    function testFuzz_GetLotsOfNodesForDelegation(uint256 amount) public {
        // call the function
        vm.prank(address(lara));
        IApyOracle.TentativeDelegation[] memory tentativeDelegations = mockApyOracle.getNodesForDelegation(amount);

        // check the length of the array
        uint256 validatorsLength = 0;
        if (amount / 80000000 ether >= validators.length) {
            validatorsLength = validators.length;
        } else if (amount % 80000000 ether == 0) {
            validatorsLength = amount / 80000000 ether;
        } else {
            validatorsLength = amount / 80000000 ether + 1;
        }
        assertEq(tentativeDelegations.length, validatorsLength, "Wrong length of array");
    }
}
