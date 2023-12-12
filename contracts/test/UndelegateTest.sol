// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow, EpochDurationNotMet} from "../errors/SharedErrors.sol";

contract UndelegateTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    fallback() external payable {}

    receive() external payable {}

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
    }

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

    function testFuzz_failsToUndelegateDuringEpoch(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 1000000 ether);
        lara.stake{value: amount}(amount);

        // reward epoch starts
        lara.startEpoch();

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration() - 1);
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration() - 1);
        vm.expectRevert("Cannot undelegate during staking epoch");
        lara.requestUndelegate(amount);

        // vm.expectRevert(EpochDurationNotMet.selector);
        // lara.endEpoch();
    }

    function testFuzz_failsToUndelegateWithoutApproval(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 1000000 ether);
        // Call the function
        address staker = address(667);

        // staker stakes

        vm.prank(staker);
        vm.deal(staker, amount);
        lara.stake{value: amount}(amount);

        // reward epoch starts
        lara.startEpoch();

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
        lara.endEpoch();

        // staker unstakes
        vm.prank(staker);
        vm.expectRevert("Amount not approved for unstaking");
        lara.requestUndelegate(amount);
    }

    function testFuzz_failsToUndelegateForSomeoneElse(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 1000000 ether);
        // Call the function
        address staker = address(667);

        // staker stakes

        vm.prank(staker);
        vm.deal(staker, amount);
        lara.stake{value: amount}(amount);

        // reward epoch starts
        lara.startEpoch();

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());

        lara.endEpoch();

        // staker unstakes
        // vm.prank(staker);
        stTaraToken.approve(address(lara), amount);
        vm.expectRevert("Amount exceeds user's delegation");
        lara.requestUndelegate(amount);
    }

    function testFuzz_singleStakeAndUnstake(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 100000000 ether);
        // Call the function
        address staker = address(667);

        // staker stakes

        vm.prank(staker);
        vm.deal(staker, amount + 1 ether);
        lara.stake{value: amount + 1 ether}(amount + 1 ether);

        // reward epoch starts
        lara.startEpoch();

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());

        lara.endEpoch();

        // staker unstakes
        vm.prank(staker);
        stTaraToken.approve(address(lara), amount);
        uint256 laraBalanceBefore = address(lara).balance;
        uint256 stTaraBalanceBefore = stTaraToken.balanceOf(address(lara));
        uint256 stTaraBalanceStakerBefore = stTaraToken.balanceOf(staker);
        uint256 stakerTaraBalanceBefore = staker.balance;
        vm.prank(staker);
        lara.requestUndelegate(amount);

        uint256 remainder = amount;
        uint8 undelegations = 0;
        if (amount % 80000000 ether > 0) {
            undelegations = 1;
        }
        undelegations += uint8(amount / 80000000 ether);
        uint256[] memory undelegationPortions = new uint256[](undelegations);
        for (uint256 i = 0; i < undelegationPortions.length; i++) {
            if ((remainder / 80000000 ether) > 0) {
                undelegationPortions[i] = 80000000 ether;
            } else {
                undelegationPortions[i] = remainder % 80000000 ether;
            }
            remainder -= undelegationPortions[i];
        }

        // staker should've received the staking rewards in ETH until now, which are 333 ETH
        uint256 stakerTaraBalanceAfter = staker.balance;
        assertEq(
            stakerTaraBalanceAfter - stakerTaraBalanceBefore,
            333 ether * undelegationPortions.length,
            "Wrong staker balance"
        );

        // staker should have less stTARA with "amount"
        uint256 stTaraBalanceStakerAfter = stTaraToken.balanceOf(staker);
        assertEq(
            stTaraBalanceStakerBefore - stTaraBalanceStakerAfter,
            amount,
            "Wrong staker stTARA balance"
        );

        // Lara stTARA or TARA balance shouldn't have changed
        uint256 laraBalanceAfter = address(lara).balance;
        assertEq(
            laraBalanceBefore,
            laraBalanceAfter,
            "Wrong lara balance after claim"
        );
        uint256 stTaraBalanceAfter = stTaraToken.balanceOf(address(this));
        assertEq(
            stTaraBalanceBefore,
            stTaraBalanceAfter,
            "Wrong stTARA balance after claim"
        );

        // staker cancels undelegate

        address delegatedToValidator = address(
            0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
        );

        vm.prank(staker);
        lara.cancelUndelegate(delegatedToValidator, undelegationPortions[0]);
    }
}
