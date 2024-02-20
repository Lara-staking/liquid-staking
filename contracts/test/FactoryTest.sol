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

    function testFuzz_anyAddressCanCreateAndDeactivateLara(
        address sample
    ) public {
        vm.assume(sample != address(0));
        vm.startPrank(sample);
        address payable laraContract = laraFactory.createLara();
        Lara laraC = Lara(laraContract);
        assertEq(laraC.owner(), address(laraFactory.owner()), "Wrong owner");
        assertEq(
            laraFactory.laraInstances(sample),
            laraContract,
            "Wrong lara instance"
        );
        laraFactory.deactivateLara(sample);
        assertEq(
            laraFactory.laraActive(laraContract),
            false,
            "Lara should be deactivated"
        );
        laraFactory.activateLara(sample);
        assertEq(
            laraFactory.laraActive(laraContract),
            true,
            "Lara should be activated"
        );
        vm.stopPrank();

        // reverts on non-owner or delegator calls
        vm.startPrank(vm.addr(23));
        vm.expectRevert("LaraFactory: Lara not created");
        laraFactory.deactivateLara(sample);
        vm.stopPrank();

        // owner calls should succeed

        laraFactory.deactivateLara(sample);
        assertEq(
            laraFactory.laraActive(laraContract),
            false,
            "Lara should be deactivated"
        );
        laraFactory.activateLara(sample);
        assertEq(
            laraFactory.laraActive(laraContract),
            true,
            "Lara should be activated"
        );
    }
}
