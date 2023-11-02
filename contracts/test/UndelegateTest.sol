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

    // set up a single staker
    function testFuzz_testStakeAndRemoveStake(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 1000000 ether);

        uint256 laraBalanceBefore = address(lara).balance;

        // Call the function
        lara.stake{value: amount}(amount);
        checkValidatorTotalStakesAreZero();

        uint256 laraBalanceAfter = address(lara).balance;

        // Check the stTara balance before
        assertEq(
            stTaraToken.balanceOf(address(this)),
            amount,
            "Wrong starting balance"
        );

        // Check the lara balance
        assertEq(
            laraBalanceAfter - laraBalanceBefore,
            amount,
            "Wrong lara balance"
        );

        // Check the remaining amount
        uint256 stakedAmount = lara.stakedAmounts(address(this));
        assertEq(stakedAmount, amount, "Wrong staked amount");
        assertEq(
            stTaraToken.balanceOf(address(this)),
            amount,
            "Wrong stTara amount given"
        );

        // Check the delegated amount
        assertEq(
            lara.stakedAmounts(address(this)),
            amount,
            "Wrong staked amount"
        );

        // Check other starting values
        assertEq(
            lara.delegatedAmounts(address(this)),
            0,
            "Wrong delegated amount"
        );
        assertEq(
            lara.claimableRewards(address(this)),
            0,
            "Wrong claimable rewards"
        );
        assertEq(
            lara.undelegated(address(this)),
            0,
            "Wrong undelegated amount"
        );

        address firstDelegator = lara.getDelegatorAtIndex(0);
        assertEq(firstDelegator, address(this), "Wrong delegator address");

        // remove the stake instantly
        uint256 laraBalanceBeforeRemove = address(lara).balance;
        uint256 stTaraBalanceBeforeRemove = stTaraToken.balanceOf(
            address(this)
        );
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
            stTaraBalanceAfterRemove - stTaraBalanceBeforeRemove,
            amount,
            "Wrong stTara balance after claim"
        );
    }

    function invariant_testStakeAndRemoveStake() public {
        uint256 laraBalanceBefore = address(lara).balance;
        uint256 stTaraBalanceBefore = stTaraToken.balanceOf(address(this));
        testFuzz_testStakeAndRemoveStake(1000 ether);
        uint256 laraBalanceAfter = address(lara).balance;
        uint256 stTaraBalanceAfter = stTaraToken.balanceOf(address(this));

        // INVARIANT 1: Lara TARA balance should be the same
        assertEq(
            laraBalanceBefore,
            laraBalanceAfter,
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
