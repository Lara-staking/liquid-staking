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

contract ReDelegateTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function stakeToASingleValidator(uint256 amount) private {
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

        // start the epoch
        lara.startEpoch();

        // end the epoch
        lara.endEpoch();
    }

    // ReDelegate from
    function testFuzz_testRedelegateStakeToSingleValidator(
        uint256 amount
    ) public {
        stakeToASingleValidator(amount);
        // re-delegate the total stake from one validator to another
        address validator1 = findValidatorWithStake(amount);
        address validator2 = validators[validators.length - 1];

        lara.reDelegate(validator1, validator2, amount);

        // check that the stake value didn't change
        assertEq(
            lara.delegatedAmounts(address(this)),
            amount,
            "ReDelegate: Wrong delegated amount"
        );

        assertEq(lara.protocolTotalStakeAtValidator(validator1), 0);
        assertEq(lara.protocolTotalStakeAtValidator(validator2), amount);

        // check the DPOS mock's validator stake
        assertEq(
            mockDpos.getValidator(validator1).total_stake,
            0,
            "Wrong validator stake"
        );

        assertEq(
            mockDpos.getValidator(validator2).total_stake,
            amount,
            "Wrong validator stake"
        );
    }

    function testFuzz_testRedelegateStakeToMultipleValidators(
        uint256 amount
    ) public {
        stakeToASingleValidator(amount);

        // re-delegate the total stake from one validator to mutiple other validators
        address validator1 = findValidatorWithStake(amount);

        address[] memory otherValidators = new address[](3);
        otherValidators[0] = validators[validators.length - 1];
        otherValidators[1] = validators[validators.length - 2];
        otherValidators[2] = validators[validators.length - 3];

        for (uint256 i = 0; i < otherValidators.length; i++) {
            lara.reDelegate(validator1, otherValidators[i], amount / 3);
        }

        // check that the stake value didn't change
        assertEq(
            lara.delegatedAmounts(address(this)),
            amount,
            "ReDelegate: Wrong delegated amount"
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(validator1),
            amount % 3,
            "Wrong total stake at initial validator"
        );
        assertEq(
            lara.protocolTotalStakeAtValidator(otherValidators[0]),
            amount / 3,
            "Wrong total stake at validator 0"
        );
        assertEq(
            lara.protocolTotalStakeAtValidator(otherValidators[1]),
            amount / 3,
            "Wrong total stake at validator 1"
        );
        assertEq(
            lara.protocolTotalStakeAtValidator(otherValidators[2]),
            amount / 3,
            "Wrong total stake at validator 2"
        );

        // check the DPOS mock's validator stake
        assertEq(
            mockDpos.getValidator(validator1).total_stake,
            amount % 3,
            "Wrong initial validator stake"
        );

        assertEq(
            mockDpos.getValidator(otherValidators[0]).total_stake,
            amount / 3,
            "Wrong validator 0 stake"
        );
        assertEq(
            mockDpos.getValidator(otherValidators[1]).total_stake,
            amount / 3,
            "Wrong validator 1 stake"
        );
        assertEq(
            mockDpos.getValidator(otherValidators[2]).total_stake,
            amount / 3,
            "Wrong validator 2 stake"
        );
    }
}
