// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUp.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/LaraErrors.sol";

contract LaraSetterTest is Test, TestSetup {
    address[] delegators = new address[](6);

    function setupDelegators() private {
        for (uint16 i = 0; i < delegators.length; i++) {
            delegators[i] = vm.addr(i + 13 * i + 13);
            vm.deal(delegators[i], 1000 ether);
            lara.stake{value: 1000 ether}(1000 ether);
        }
    }

    function setUp() public {
        for (uint16 i = 0; i < validators.length; i++) {
            validators[i] = vm.addr(i + 1);
        }
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        setupDelegators();
    }

    function testFuzz_setMaxValdiatorStakeCapacity(address setter) public {
        vm.assume(setter != address(0));
        // get owner
        address owner = lara.owner();

        if (setter != owner) {
            vm.prank(setter);
            vm.expectRevert("Ownable: caller is not the owner");
            lara.setMaxValidatorStakeCapacity(1000 ether);
            return;
        } else {
            lara.setMaxValidatorStakeCapacity(1000 ether);
            assertEq(
                lara.maxValidatorStakeCapacity(),
                1000 ether,
                "Max validator stake capacity not set correctly"
            );
        }
    }

    function testFuzz_setMinStakeAmount(address setter) public {
        vm.assume(setter != address(0));
        // get owner
        address owner = lara.owner();

        if (setter != owner) {
            vm.prank(setter);
            vm.expectRevert("Ownable: caller is not the owner");
            lara.setMinStakeAmount(1000 ether);
            return;
        } else {
            lara.setMinStakeAmount(1000 ether);
            assertEq(
                lara.minStakeAmount(),
                1000 ether,
                "Max validator stake capacity not set correctly"
            );
        }
    }
}
