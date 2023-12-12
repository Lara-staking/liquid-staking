// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTestLotsOfValidators.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/SharedErrors.sol";

contract MassRebalanceTest is Test, ManyValidatorsTestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function stakeFromMultipleDelegatorsToMultipleValidators(
        uint256 total
    ) public {
        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            uint256 laraBalanceBefore = address(lara).balance;
            // Call the function
            vm.deal(delegator, amount);
            vm.prank(delegator);
            lara.stake{value: amount}(amount);
            checkValidatorTotalStakesAreZero();
            uint256 laraBalanceAfter = address(lara).balance;

            // Check the stTara balance before
            assertEq(
                stTaraToken.balanceOf(delegator),
                amount,
                "Wrong stTARA balance"
            );

            // Check the lara balance
            assertEq(
                laraBalanceAfter - laraBalanceBefore,
                amount,
                "Wrong lara balance"
            );

            // Check the staked amount
            assertEq(
                lara.stakedAmounts(delegator),
                amount,
                "Wrong staked amount"
            );

            // Check the other amounts
            assertEq(
                lara.delegatedAmounts(delegator),
                0,
                "Wrong delegated amount"
            );
            assertEq(
                lara.claimableRewards(delegator),
                0,
                "Wrong claimable rewards"
            );
            assertEq(
                lara.undelegated(delegator),
                0,
                "Wrong undelegated amount"
            );

            address firstDelegator = lara.getDelegatorAtIndex(i - 1);
            assertEq(firstDelegator, delegator, "Wrong delegator address");
        }

        // start the epoch
        lara.startEpoch();

        vm.warp(lara.lastEpochStartBlock() + lara.epochDuration());
        vm.roll(lara.lastEpochStartBlock() + lara.epochDuration());
        // end the epoch
        lara.endEpoch();
    }

    function testFuzz_testRedelegateStakeFromMultipleDelegatorsToMultipleValidators(
        uint256 total
    ) public {
        vm.assume(total > 80000000 ether);
        vm.assume(total < 12000000000 ether);
        stakeFromMultipleDelegatorsToMultipleValidators(total);

        address firstInOracleNodesList = mockApyOracle.nodesList(0);

        // update the validator list in the oracle
        this.batchUpdateNodeData(1, true);

        address firstInOracleNodesListAfter = mockApyOracle.nodesList(0);

        assertNotEq(
            firstInOracleNodesList,
            firstInOracleNodesListAfter,
            "First node in oracle nodes list should have changed"
        );

        uint256 totalDelegatedInLastEpoch = lara
            .lastEpochTotalDelegatedAmount();

        lara.rebalance();

        // check that the stake value didn't change
        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            assertApproxEqAbs(
                lara.delegatedAmounts(delegator),
                amount,
                1000,
                "ReDelegate: Wrong delegated amount"
            );
        }
        uint256 nodesToBeFilled = total / 80000000 ether;
        uint256 modulo = total % 80000000 ether;
        if (modulo > 0) {
            nodesToBeFilled += 1;
        }
        uint256 totalDelegatedAfterRebalance = 0;
        for (uint256 i = 0; i < nodesToBeFilled; i++) {
            assertGt(
                lara.protocolTotalStakeAtValidator(mockApyOracle.nodesList(i)),
                0,
                "LARA: Validator should have stake"
            );
            // check the DPOS mock's validator stake
            assertGt(
                mockDpos.getValidator(mockApyOracle.nodesList(i)).total_stake,
                0,
                "DPOS: Validator should have stake"
            );
            totalDelegatedAfterRebalance += lara.protocolTotalStakeAtValidator(
                mockApyOracle.nodesList(i)
            );
        }
        assertEq(
            totalDelegatedAfterRebalance,
            totalDelegatedInLastEpoch,
            "LARA: Total delegated amount should not change"
        );
    }
}
