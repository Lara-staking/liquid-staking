// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTestLotsOfValidators.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";

contract MassRebalanceTest is Test, ManyValidatorsTestSetup {
    uint256 totalDelegated = 0;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraFactoryWithCommission(3);
        super.createLara();
    }

    function stakeFromMultipleDelegatorsToMultipleValidators(
        uint256 total
    ) public {
        uint256 totalStaked = 0;
        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            // Deploy Lara for delegator
            vm.prank(delegator);
            address payable laraA = laraFactory.createLara();
            Lara laraI = Lara(laraA);

            uint256 laraBalanceBefore = address(laraI).balance;
            uint256 dposBalanceBefore = address(mockDpos).balance;
            // Call the function
            vm.deal(delegator, amount);
            vm.prank(delegator);
            laraI.stake{value: amount}(amount);
            totalStaked += amount;
            uint256 laraBalanceAfter = address(laraI).balance;
            uint256 dposBalanceAfter = address(mockDpos).balance;

            // Check the stTara balance before
            assertEq(
                stTaraToken.balanceOf(delegator),
                amount,
                "Wrong stTARA balance"
            );

            // Check the lara balance
            assertEq(
                laraBalanceAfter - laraBalanceBefore,
                0,
                "Wrong lara balance"
            );

            assertEq(
                dposBalanceAfter - dposBalanceBefore,
                amount,
                "Wrong lara balance"
            );

            assertEq(laraI.totalDelegated(), amount, "Wrong staked amount");
            vm.roll(laraI.lastSnapshot() + laraI.epochDuration());
        }
        totalDelegated = totalStaked;
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

        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            vm.prank(delegator);
            address laraA = laraFactory.laraInstances(delegator);
            Lara laraI = Lara(payable(laraA));
            assertApproxEqAbs(
                stTaraToken.balanceOf(delegator),
                amount,
                1000,
                "ReDelegate: Wrong delegated amount"
            );
            uint256 nodesToBeFilled = laraI.totalDelegated() / 80000000 ether;
            uint256 modulo = laraI.totalDelegated() % 80000000 ether;
            if (modulo > 0) {
                nodesToBeFilled += 1;
            }
            uint256 totalDelegatedAfterRebalance = 0;
            for (uint256 j = 0; j < nodesToBeFilled; j++) {
                assertGt(
                    laraI.totalStakeAtValidator(laraI.validators(j)),
                    0,
                    "LARA: Validator should have stake"
                );
                // check the DPOS mock's validator stake
                assertGt(
                    mockDpos.getValidator(laraI.validators(j)).total_stake,
                    0,
                    "DPOS: Validator should have stake"
                );
                totalDelegatedAfterRebalance += laraI.totalStakeAtValidator(
                    laraI.validators(j)
                );
            }
        }

        // check that the stake value didn't change
        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            vm.prank(delegator);
            address laraA = laraFactory.laraInstances(delegator);
            Lara laraI = Lara(payable(laraA));
            laraI.rebalance();
            assertApproxEqAbs(
                stTaraToken.balanceOf(delegator),
                amount,
                1000,
                "ReDelegate: Wrong delegated amount"
            );
            uint256 nodesToBeFilled = laraI.totalDelegated() / 80000000 ether;
            uint256 modulo = laraI.totalDelegated() % 80000000 ether;
            if (modulo > 0) {
                nodesToBeFilled += 1;
            }
            uint256 totalDelegatedAfterRebalance = 0;
            for (uint256 j = 0; j < nodesToBeFilled; j++) {
                assertEq(
                    laraI.totalStakeAtValidator(laraI.validators(j)),
                    0,
                    "LARA: Validator should be empty"
                );
                totalDelegatedAfterRebalance += laraI.totalStakeAtValidator(
                    laraI.validators(j)
                );
            }
        }
    }
}
