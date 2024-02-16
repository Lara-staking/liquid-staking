// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";

contract FactoryTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraFactoryWithCommission(3);
    }

    function test_firstDelegatorCreatesLara() public {
        super.createLara();
    }

    function testFuzz_anyAddressCanCreateLara(address sample) public {
        vm.assume(sample != address(0));
        vm.prank(sample);
        address payable laraContract = laraFactory.createLara();
        Lara laraC = Lara(laraContract);
        assertEq(laraC.owner(), address(laraFactory.owner()), "Wrong owner");
        assertEq(
            laraFactory.laraInstances(sample),
            laraContract,
            "Wrong lara instance"
        );
    }
}
