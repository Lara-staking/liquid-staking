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

contract RebalanceTest is Test, TestSetup {
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

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
        // end the epoch
        lara.endEpoch();
    }

    function stakeToMultipleValidators(uint256 amount) private {
        uint256 laraBalanceBefore = address(lara).balance;

        // Call the function
        vm.assume(amount > 80000000 ether);
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

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
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
        // address validator2 = validators[validators.length - 1];

        lara.rebalance();

        // check that the stake value didn't change
        assertEq(
            lara.delegatedAmounts(address(this)),
            amount,
            "ReDelegate: Wrong delegated amount"
        );

        assertEq(lara.protocolTotalStakeAtValidator(validator1), amount);

        // check the DPOS mock's validator stake
        assertEq(
            mockDpos.getValidator(validator1).total_stake,
            amount,
            "Wrong validator stake"
        );
    }

    function testFuzz_testRedelegateStakeToMultipleValidators(
        uint256 amount
    ) public {
        vm.assume(amount > 80000000 ether);
        vm.assume(amount < 800000000 ether);
        stakeToMultipleValidators(amount);

        address firstInOracleNodesList = mockApyOracle.nodesList(0);

        // update the validator list in the oracle
        this.batchUpdateNodeData(1, true);

        address firstInOracleNodesListAfter = mockApyOracle.nodesList(0);

        assertNotEq(
            firstInOracleNodesList,
            firstInOracleNodesListAfter,
            "First node in oracle nodes list should have changed"
        );

        uint256 protocolStakeAtCurrentFirst = lara
            .protocolTotalStakeAtValidator(firstInOracleNodesList);

        uint256 protocolStakeAtNextFirstBefore = lara
            .protocolTotalStakeAtValidator(firstInOracleNodesListAfter);

        assertGt(
            protocolStakeAtCurrentFirst,
            0,
            "Protocol stake at first node should be bigger than zero"
        );

        assertEq(
            protocolStakeAtNextFirstBefore,
            0,
            "Protocol stake at first node should still be zero"
        );

        lara.rebalance();

        // check that the stake value didn't change
        assertEq(
            lara.delegatedAmounts(address(this)),
            amount,
            "ReDelegate: Wrong delegated amount"
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(firstInOracleNodesList),
            0,
            "Wrong total stake at initial validator"
        );
        assertEq(
            lara.protocolTotalStakeAtValidator(firstInOracleNodesListAfter),
            protocolStakeAtCurrentFirst,
            "Wrong total stake at validator after"
        );

        // check the DPOS mock's validator stake
        assertEq(
            mockDpos.getValidator(firstInOracleNodesListAfter).total_stake,
            protocolStakeAtCurrentFirst,
            "Wrong initial validator stake"
        );

        assertEq(
            mockDpos.getValidator(firstInOracleNodesList).total_stake,
            0,
            "Wrong validator 0  stake on successful rebalance"
        );
    }

    function testFuzz_testDoNotRedelegateStakeToMultipleValidators(
        uint256 amount
    ) public {
        vm.assume(amount > 80000000 ether);
        vm.assume(amount < 800000000 ether);
        stakeToMultipleValidators(amount);

        address firstInOracleNodesList = mockApyOracle.nodesList(0);

        // update the validator list in the oracle
        this.batchUpdateNodeData(1, false);

        address firstInOracleNodesListAfter = mockApyOracle.nodesList(0);

        assertEq(
            firstInOracleNodesList,
            firstInOracleNodesListAfter,
            "First node in oracle nodes list should not have changed"
        );

        uint256 protocolStakeAtCurrentFirst = lara
            .protocolTotalStakeAtValidator(firstInOracleNodesList);

        uint256 protocolStakeAtNextFirstBefore = lara
            .protocolTotalStakeAtValidator(firstInOracleNodesListAfter);

        assertEq(
            protocolStakeAtCurrentFirst,
            protocolStakeAtNextFirstBefore,
            "Validator initial delegation should be the same"
        );

        lara.rebalance();

        // check that the stake value didn't change
        assertEq(
            lara.delegatedAmounts(address(this)),
            amount,
            "ReDelegate: Wrong delegated amount"
        );

        assertEq(
            lara.protocolTotalStakeAtValidator(firstInOracleNodesList),
            protocolStakeAtCurrentFirst,
            "Wrong total stake at initial validator"
        );
        assertEq(
            lara.protocolTotalStakeAtValidator(firstInOracleNodesListAfter),
            protocolStakeAtCurrentFirst,
            "Wrong total stake at validator after"
        );

        // check the DPOS mock's validator stake
        assertEq(
            mockDpos.getValidator(firstInOracleNodesList).total_stake,
            protocolStakeAtCurrentFirst,
            "Wrong initial validator stake"
        );

        assertEq(
            mockDpos.getValidator(firstInOracleNodesListAfter).total_stake,
            protocolStakeAtCurrentFirst,
            "Wrong secondary(same) validator stakes"
        );
    }
}
