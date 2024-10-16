// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "@contracts/interfaces/IApyOracle.sol";
import {Lara} from "@contracts/Lara.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";
import {MockDpos} from "@contracts/mocks/MockDpos.sol";
import {StakedNativeAsset} from "@contracts/StakedNativeAsset.sol";
import {ManyValidatorsTestSetup} from "@contracts/test/SetUpLotsOfValidators.t.sol";
import {StakeAmountTooLow} from "@contracts/libs/SharedErrors.sol";

contract MassRebalanceTest is Test, ManyValidatorsTestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function stakeFromMultipleDelegatorsToMultipleValidators(uint256 total) public {
        uint256 totalStaked = 0;
        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            uint256 laraBalanceBefore = address(lara).balance;
            uint256 dposBalanceBefore = address(mockDpos).balance;
            // Call the function
            vm.deal(delegator, amount);
            vm.prank(delegator);
            lara.stake{value: amount}(amount);
            totalStaked += amount;
            uint256 laraBalanceAfter = address(lara).balance;
            uint256 dposBalanceAfter = address(mockDpos).balance;

            // Check the stTara balance before
            assertEq(stTaraToken.balanceOf(delegator), amount, "Wrong stTARA balance");

            // Check the lara balance
            assertEq(laraBalanceAfter - laraBalanceBefore, 0, "Wrong lara balance");

            assertEq(dposBalanceAfter - dposBalanceBefore, amount, "Wrong lara balance");

            assertEq(lara.undelegated(delegator), 0, "Wrong undelegated amount");
        }

        vm.roll(lara.lastSnapshotBlock() + lara.epochDuration());
    }

    function testFuzz_testRedelegateStakeFromMultipleDelegatorsToMultipleValidators(uint256 total) public {
        vm.assume(total > 80000000 ether);
        vm.assume(total < 12000000000 ether);
        stakeFromMultipleDelegatorsToMultipleValidators(total);

        address firstInOracleNodesList = mockApyOracle.nodesList(0);

        // update the validator list in the oracle
        this.batchUpdateNodeData(1, true);

        address firstInOracleNodesListAfter = mockApyOracle.nodesList(0);

        assertNotEq(
            firstInOracleNodesList, firstInOracleNodesListAfter, "First node in oracle nodes list should have changed"
        );

        lara.rebalance();

        // check that the stake value didn't change
        for (uint256 i = 1; i < 6; i++) {
            uint256 amount = total / 5;
            address delegator = address(uint160(i));
            assertApproxEqAbs(stTaraToken.balanceOf(delegator), amount, 1000, "ReDelegate: Wrong delegated amount");
        }
        uint256 nodesToBeFilled = total / 80000000 ether;
        uint256 modulo = total % 80000000 ether;
        if (modulo > 0) {
            nodesToBeFilled += 1;
        }
    }

    function invariant_stakeSameAfterMassRebalance() public {
        uint256 totalSupplyBefore = stTaraToken.totalSupply();
        stakeFromMultipleDelegatorsToMultipleValidators(100000 ether);
        assertTrue(
            (totalSupplyBefore + 100000 ether) == stTaraToken.totalSupply(), "Total delegated not equal to total supply"
        );
    }
}
