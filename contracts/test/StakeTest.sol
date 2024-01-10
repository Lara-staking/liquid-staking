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

contract StakeTest is Test, TestSetup {
    uint256 epochDuration = 0;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
    }

    function stakeAndUnstake(uint256 amount) public {
        // Call the stake function
        lara.stake{value: amount}(amount);

        // Check the staked amount
        assertEq(address(lara).balance, amount, "Wrong staked amount");
        assertEq(
            stTaraToken.balanceOf(address(this)),
            amount,
            "Wrong staked amount"
        );

        stTaraToken.approve(address(lara), amount);
        // Call the unstake function
        lara.unstake(amount);

        // Check the unstaked amount
        assertEq(address(lara).balance, 0, "Wrong unstaked amount");
    }

    function testStakeAndUnstake() public {
        uint256 amount = 500000 ether;

        stakeAndUnstake(amount);
    }

    function testFailStakeAmountTooLow() public {
        // Call the function with an amount less than the minimum stake amount
        vm.expectRevert(StakeAmountTooLow.selector);
        lara.stake{value: 500 ether}(500 ether);
    }

    function testFailStakeValueTooLow() public {
        // Call the function with a value less than the staking amount
        vm.expectRevert(StakeValueTooLow.selector);
        lara.stake{value: 400000 ether}(500000 ether);
    }

    function testFailUnstakeAmountTooHigh() public {
        // Call the function with an amount greater than the staked amount
        vm.expectRevert(
            "revert: LARA: Not enough assets unstaked, use requestUndelegate instead"
        );
        lara.unstake(6000000 ether);
    }

    function testNotRegisteredTwice() public {
        uint256 amount = 500000 ether;

        // Call the stake function
        lara.stake{value: amount}(amount);

        assertEq(lara.delegators(0), address(this));

        vm.expectRevert();
        assertEq(lara.delegators(1), address(0));

        lara.stake{value: amount}(amount);

        assertEq(lara.delegators(0), address(this));

        vm.expectRevert();
        assertEq(lara.delegators(1), address(0));
    }

    function testFuzz_stakeAndUnstake(uint256 amount) public {
        vm.assume(amount > lara.minStakeAmount());
        vm.deal(address(this), amount);
        stakeAndUnstake(amount);
    }

    function invariant_stakeAndUnstake() public {
        stakeAndUnstake(100000 ether);
        assertTrue(address(lara).balance == stTaraToken.totalSupply());
    }

    function testFuzz_unstakeMoreThanStaked(uint256 amount) public {
        vm.assume(amount > lara.minStakeAmount());
        vm.assume(amount < 10000000000 ether);
        vm.deal(address(this), amount);
        lara.stake{value: amount}(amount);
        stTaraToken.approve(address(lara), amount + 1);
        vm.expectRevert();
        lara.unstake(amount + 1);
    }
}
