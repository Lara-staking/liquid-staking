// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../Lara.sol";
import "../mocks/MockDpos.sol";
import "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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
            bytes4 selector = bytes4(
                keccak256(bytes("OwnableUnauthorizedAccount(address)"))
            );
            vm.expectRevert(abi.encodeWithSelector(selector, setter));
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
            bytes4 selector = bytes4(
                keccak256(bytes("OwnableUnauthorizedAccount(address)"))
            );
            vm.expectRevert(abi.encodeWithSelector(selector, setter));
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
