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
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

contract DelegateTest is Test, TestSetup {
    uint256 epochDuration = 0;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
    }

    function testGetNodesForDelegation() public {
        // define value
        uint256 amount = 500000 ether;

        // call the function
        vm.prank(address(lara));
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // check the length of the array
        assertEq(tentativeDelegations.length, 1, "Wrong length of array");

        // check if the value is the right one. It should be 500000 ether for the first validator
        assertEq(tentativeDelegations[0].amount, amount, "Wrong value");
    }

    function testFuzz_GetNodesForDelegation(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 94800000 ether);
        // call the function
        vm.prank(address(lara));
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // check the length of the array
        assertTrue(
            tentativeDelegations.length >= 1,
            "Wrong length of array: delegations should always get at least one validator"
        );

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tentativeDelegations.length; i++) {
            totalAmount += tentativeDelegations[i].amount;
        }

        // check if the value is the right one. It should be 500000 ether for the first validator
        assertEq(totalAmount, amount, "Wrong total delegated value");
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

    uint256 firstAmountToStake = 500000 ether;

    function testFuzz_testStakeToSingleValidator(uint256 amount) public {
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
    }

    event DelegationReward(uint256 totalStakes, uint256 totalRewards);

    function testStakeToMultipleValidators() public {
        uint256 amount = 100000000 ether; // 1 full node + 20mil

        // Call the function with different address
        address staker1 = address(333);
        vm.prank(staker1);
        vm.deal(staker1, amount + 1 ether);
        uint256 balanceBefore = address(lara).balance;
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
        vm.roll(epochDuration + lara.lastEpochStartBlock());
        lara.endEpoch();

        address firstValidatorDelegated = findValidatorWithStake(
            80000000 ether
        );
        address secondValidatorDelegated = findValidatorWithStake(
            20000000 ether
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(firstValidatorDelegated),
            80000000 ether,
            "Wrong total stake at validator"
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(secondValidatorDelegated),
            20000000 ether,
            "Wrong total stake at validator"
        );

        assertEq(
            mockDpos.getValidator(firstValidatorDelegated).total_stake,
            80000000 ether,
            "Wrong total stake at validator in mockDpos"
        );

        assertEq(
            mockDpos.getValidator(secondValidatorDelegated).total_stake,
            20000000 ether,
            "Wrong total stake at validator in mockDpos"
        );

        uint256 balanceOfStakerAfter = address(staker1).balance;
        assertEq(
            lara.delegatedAmounts(staker1),
            amount,
            "Delegated amounts changed"
        );
        assertEq(
            lara.claimableRewards(staker1),
            1000100 ether,
            "Staker should have received rewards"
        );

        assertEq(
            balanceOfStakerAfter,
            balanceOfStakerBefore,
            "Staker balance should not have changed"
        );
    }

    function testFailValidatorsFull() public {
        uint256 amount = 100000000 ether;

        // Call the function with different address
        address staker2 = address(444);
        vm.prank(staker2);
        vm.deal(staker2, amount + 1 ether);
        vm.expectRevert("No amount could be staked. Validators are full.");
        lara.stake{value: amount}(amount);
    }
}
