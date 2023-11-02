// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

contract LaraTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    fallback() external payable {}

    receive() external payable {}

    // set up a single staker
    function testFuzz_testStakeAndRemoveStake(uint256 amount) public {}

    function invariant_testStakeAndRemoveStake() public {
        uint256 laraBalanceBefore = address(lara).balance;
        uint256 stTaraBalanceBefore = stTaraToken.balanceOf(address(this));

        uint256 amount = 500000 ether;
        // Call the function
        lara.stake{value: amount}(amount);
        // remove the stake instantly
        uint256 laraBalanceBeforeRemove = address(lara).balance;
        stTaraToken.approve(address(lara), amount);
        lara.removeStake(amount);
        uint256 laraBalanceAfterRemove = address(lara).balance;
        uint256 stTaraBalanceAfterRemove = stTaraToken.balanceOf(address(this));

        // check the lara balance
        assertEq(
            laraBalanceBeforeRemove - laraBalanceAfterRemove,
            amount,
            "Wrong lara balance after claim"
        );

        // check the stTara balance
        assertEq(
            stTaraBalanceAfterRemove,
            0,
            "Wrong stTara balance after claim"
        );

        uint256 stTaraBalanceAfter = stTaraToken.balanceOf(address(this));

        // INVARIANT 1: Lara TARA balance should be the same
        assertEq(
            laraBalanceBefore,
            laraBalanceAfterRemove,
            "Lara balance should be the same"
        );

        // INVARIANT 2: stTARA balance should be the same
        assertEq(
            stTaraBalanceBefore,
            stTaraBalanceAfter,
            "stTARA balance should be the same"
        );
    }
}
