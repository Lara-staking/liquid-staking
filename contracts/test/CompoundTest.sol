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
    address staker0 = address(this);
    address staker1 = address(333);

    uint256 constant MAX_VALIDATOR_STAKE_CAPACITY = 80000000 ether;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function checkValidatorTotalStakesAreZero() private {
        for (uint256 i = 0; i < validators.length; i++) {
            assertEq(
                lara.protocolTotalStakeAtValidator(validators[i]),
                0,
                "Validator total stake should be zero"
            );
            uint256 total_stake = mockDpos
                .getValidator(validators[i])
                .total_stake;
            assertEq(
                total_stake,
                0,
                "Validator total stake should be zero in mockDpos"
            );
        }
    }

    function findValidatorWithStake(
        uint256 stake
    ) private view returns (address) {
        for (uint256 i = 0; i < validators.length; i++) {
            if (lara.protocolTotalStakeAtValidator(validators[i]) == stake) {
                return validators[i];
            }
        }
        return address(0);
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

    // now we launch a second epoch without compound being set
    function test_launchNextEpoch() public {}
}
