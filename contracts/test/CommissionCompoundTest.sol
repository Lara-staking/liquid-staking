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
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

contract CommissionTest is Test, TestSetup {
    address staker0 = address(this);
    address staker1 = address(333);
    address staker2 = address(444);

    uint256 constant MAX_VALIDATOR_STAKE_CAPACITY = 80000000 ether;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraWithCommission(10);
    }

    function getTotalDposStake() public view returns (uint256) {
        uint256 totalDposStake = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            totalDposStake += mockDpos.getValidator(validators[i]).total_stake;
        }
        return totalDposStake;
    }

    function testFuzz_testStakeToSingleValidator(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < MAX_VALIDATOR_STAKE_CAPACITY);

        uint256 laraBalanceBefore = address(lara).balance;

        // Call the function
        vm.prank(staker0);
        lara.stake{value: amount}(amount);
        checkValidatorTotalStakesAreZero();

        uint256 laraBalanceAfter = address(lara).balance;

        // Check the stTara balance before
        assertEq(
            stTaraToken.balanceOf(staker0),
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
        uint256 stakedAmount = lara.stakedAmounts(staker0);
        assertEq(stakedAmount, amount, "Wrong staked amount");
        assertEq(
            stTaraToken.balanceOf(staker0),
            amount,
            "Wrong stTara amount given"
        );

        // Check the delegated amount
        assertEq(lara.stakedAmounts(staker0), amount, "Wrong staked amount");

        // Check other starting values
        assertEq(lara.delegatedAmounts(staker0), 0, "Wrong delegated amount");
        assertEq(lara.claimableRewards(staker0), 0, "Wrong claimable rewards");
        assertEq(lara.undelegated(staker0), 0, "Wrong undelegated amount");

        address firstDelegator = lara.getDelegatorAtIndex(0);
        assertEq(firstDelegator, staker0, "Wrong delegator address");
    }

    function testStakeToMultipleValidators() public {
        // The previous stake isn't available because it was a fuzz test

        uint256 amount = 100000000 ether; // 1 full node + 20mil

        // Call the function with different address
        uint256 balanceBefore = address(lara).balance;
        vm.prank(staker1);
        vm.deal(staker1, amount + 1 ether);
        lara.stake{value: amount}(amount);
        checkValidatorTotalStakesAreZero();
        uint256 balanceAfter = address(lara).balance;

        // Check the remaining amount
        assertEq(balanceAfter - balanceBefore, amount, "Wrong amount given");
        assertEq(
            stTaraToken.balanceOf(address(staker1)),
            amount,
            "Wrong stTara amount accredited"
        );
        // Check the delegated amount
        assertEq(lara.stakedAmounts(staker1), amount, "Wrong staked amount");

        // start the epoch
        lara.startEpoch();

        assertEq(
            lara.lastEpochTotalDelegatedAmount(),
            amount,
            "Wrong total amount"
        );
        assertEq(
            lara.stakedAmounts(staker1),
            0,
            "Wrong staked amount after epoch start"
        );
        assertEq(
            lara.delegatedAmounts(staker1),
            amount,
            "Wrong delegated amount after epoch start"
        );

        // end the epoch
        uint256 balanceOfStakerBefore = address(staker1).balance;
        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
        lara.endEpoch();

        address firstValidatorDelegated = findValidatorWithStake(
            MAX_VALIDATOR_STAKE_CAPACITY
        );
        address secondValidatorDelegated = findValidatorWithStake(
            20000000 ether
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(firstValidatorDelegated),
            MAX_VALIDATOR_STAKE_CAPACITY,
            "Wrong total stake at validator"
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(secondValidatorDelegated),
            20000000 ether,
            "Wrong total stake at validator"
        );

        assertEq(
            mockDpos.getValidator(firstValidatorDelegated).total_stake,
            MAX_VALIDATOR_STAKE_CAPACITY,
            "Wrong total stake at validator in mockDpos"
        );

        assertEq(
            mockDpos.getValidator(secondValidatorDelegated).total_stake,
            20000000 ether,
            "Wrong total stake at validator in mockDpos"
        );

        uint256 balanceOfStakerAfter = address(staker1).balance;
        uint256 totalRewards = amount / 100 + 100 ether;
        uint256 expectedCommission = (totalRewards * lara.commission()) / 100;
        assertEq(
            lara.delegatedAmounts(staker1),
            amount,
            "Delegated amounts changed"
        );
        assertEq(
            lara.claimableRewards(staker1),
            totalRewards - expectedCommission,
            "Staker should have received rewards"
        );
        assertEq(
            address(lara.treasuryAddress()).balance,
            expectedCommission,
            "Treasurer should have received commission"
        );

        assertEq(
            balanceOfStakerAfter,
            balanceOfStakerBefore,
            "Staker balance should not have changed"
        );
    }

    function calculateExpectedRewardForUser(
        address staker
    ) public returns (uint256, uint256) {
        uint256 totalRewards = getTotalDposStake() / 100 + 100 ether;
        uint256 commission = (totalRewards * lara.commission()) / 100;

        uint256 stakerDelegated = lara.delegatedAmounts(staker);
        uint256 totalDelegatedInLastEpoch = lara
            .lastEpochTotalDelegatedAmount();

        uint256 expectedRewardStaker = (stakerDelegated *
            (totalRewards - commission)) / totalDelegatedInLastEpoch;
        return (expectedRewardStaker, commission);
    }

    // now we launch a second epoch without compound being set
    function test_commission_launchNextEpoch() public {
        // staker 1 stakes 100000 ether
        vm.prank(staker1);
        vm.deal(staker1, 100000 ether);
        lara.stake{value: 100000 ether}(100000 ether);

        // staker2 stakes 100000 ether
        vm.prank(staker2);
        vm.deal(staker2, 100000 ether);
        lara.stake{value: 100000 ether}(100000 ether);

        // we start the epoch
        lara.startEpoch();

        uint256 epochDuration = lara.epochDuration();

        assertEq(
            lara.lastEpochTotalDelegatedAmount(),
            200000 ether, // there were no other delegations
            "Wrong total amount"
        );

        // we end the epoch
        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
        lara.endEpoch();

        // check the rewards
        (
            uint256 expectedRewardStaker1,
            uint256 commission
        ) = calculateExpectedRewardForUser(staker1);
        (uint256 expectedRewardStaker2, ) = calculateExpectedRewardForUser(
            staker2
        );

        assertEq(
            address(lara.treasuryAddress()).balance,
            commission,
            "Treasurer should have received commission"
        );

        assertEq(
            expectedRewardStaker1,
            expectedRewardStaker2,
            "Rewards should be the same"
        );
        uint256 delegatedAmountStaker1 = lara.delegatedAmounts(staker1);
        uint256 delegatedAmountStaker2 = lara.delegatedAmounts(staker2);
        uint256 claimableRewardsStaker1 = lara.claimableRewards(staker1);
        uint256 claimableRewardsStaker2 = lara.claimableRewards(staker2);
        assertEq(
            claimableRewardsStaker1,
            expectedRewardStaker1,
            "Staker1 should have received rewards after first epoch"
        );
        assertEq(
            claimableRewardsStaker2,
            expectedRewardStaker2,
            "Staker2 should have received rewards after first epoch"
        );

        // staker1 turns auto-compound on
        vm.prank(staker1);
        lara.setCompound(true);

        // new epoch starts
        lara.startEpoch();

        // check if the delegated amount now contains the rewards of staker1
        assertEq(
            lara.claimableRewards(staker1),
            0,
            "Staker1 compounded so claimable rewards should be 0"
        );
        assertEq(
            lara.delegatedAmounts(staker1),
            delegatedAmountStaker1 + claimableRewardsStaker1,
            "Staker1 should have bigger delegated amount after first epoch"
        );

        // check if the delegated amount of staker2 is the same
        assertEq(
            lara.delegatedAmounts(staker2),
            delegatedAmountStaker2,
            "Staker2 should have the same delegated amount after first epoch"
        );

        // new epoch ends
        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
        lara.endEpoch();

        // check rewards, they should be higher for staker1 but the same for staker2

        (
            uint256 expectedRewardStaker1AfterCompound,
            uint256 commissionSecond
        ) = calculateExpectedRewardForUser(staker1);

        // check the treasury balance
        assertEq(
            address(lara.treasuryAddress()).balance,
            commission + commissionSecond,
            "Treasury should have received all commissions"
        );

        assertEq(
            lara.claimableRewards(staker1),
            expectedRewardStaker1AfterCompound,
            "Staker1 should have received rewards after second epoch"
        );

        assertApproxEqRel(
            lara.claimableRewards(staker2),
            expectedRewardStaker2 * 2,
            0.04e18,
            "Staker2 should have received rewards after second epoch"
        );

        // staker1 claims rewards
        uint256 balanceOfStakerBefore = address(staker1).balance;
        uint256 balanceOfTreasuryBefore = address(treasuryAddress).balance;
        vm.prank(staker1);
        lara.claimRewards();
        uint256 balanceOfStakerAfter = address(staker1).balance;

        // staker1 should have received expectedRewardStaker1AfterCompound
        assertEq(
            balanceOfStakerAfter - balanceOfStakerBefore,
            expectedRewardStaker1AfterCompound,
            "staker1 should have received expectedRewardStaker1 + expectedRewardStaker1AfterCompound"
        );

        // check treasury balance
        assertEq(
            address(lara.treasuryAddress()).balance,
            commission + commissionSecond,
            "Treasury should have received commission"
        );

        // staker2 claims rewards
        balanceOfStakerBefore = address(staker2).balance;
        vm.prank(staker2);
        lara.claimRewards();
        balanceOfStakerAfter = address(staker2).balance;

        (expectedRewardStaker2, ) = calculateExpectedRewardForUser(staker2);
        expectedRewardStaker2 = expectedRewardStaker2 * 2;

        // staker2 should have received expectedRewardStaker2 * 2
        assertApproxEqRel(
            balanceOfStakerAfter - balanceOfStakerBefore,
            expectedRewardStaker2,
            0.04e18,
            "staker2 should have received twice the rewards -  10%"
        );
    }
}
