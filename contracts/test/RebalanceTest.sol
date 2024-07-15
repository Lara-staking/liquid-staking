// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "../interfaces/IApyOracle.sol";
import {Lara} from "../Lara.sol";
import {ApyOracle} from "../ApyOracle.sol";
import {MockDpos} from "../mocks/MockDpos.sol";
import {stTara} from "../stakedTara.sol";
import {TestSetup} from "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";

contract RebalanceTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function stake(uint256 amount) private {
        vm.assume(amount > 1000 ether);

        uint256 dposBalanceBefore = address(mockDpos).balance;

        // Call the function
        lara.stake{value: amount}(amount);

        uint256 dposBalanceAfter = address(mockDpos).balance;

        // Check the stTara balance before
        assertEq(stTaraToken.balanceOf(address(this)), amount, "Wrong starting balance");

        // Check the dpos balance
        assertEq(dposBalanceAfter - dposBalanceBefore, amount, "Wrong dpos balance");

        // Check the delegated amount
        assertEq(lara.totalDelegated(), amount, "Wrong staked amount");

        // Check other starting values
        assertEq(lara.delegators(0), address(this), "Wrong delegator");

        // start the epoch
        lara.snapshot();

        vm.roll(lara.lastSnapshot() + lara.epochDuration());
    }

    // ReDelegate from
    function testFuzz_testRedelegateStakeToSingleValidator(uint256 amount) public {
        vm.assume(amount < 80000000 ether);
        stake(amount);
        // re-delegate the total stake from one validator to another
        address validator1 = findValidatorWithStake(amount);
        // address validator2 = validators[validators.length - 1];

        uint256 totalDelgatedbefore = lara.totalDelegated();
        lara.rebalance();

        // check that the stake value didn't change
        assertEq(lara.totalDelegated(), totalDelgatedbefore, "ReDelegate: Wrong delegated amount");

        assertEq(lara.protocolTotalStakeAtValidator(validator1), amount);

        // check the DPOS mock's validator stake
        assertEq(mockDpos.getValidator(validator1).total_stake, amount, "Wrong validator stake");
    }

    function testFuzz_testRedelegateStakeToMultipleValidators(uint256 amount) public {
        vm.assume(amount > 80000000 ether);
        vm.assume(amount < 800000000 ether);
        stake(amount);

        address firstInOracleNodesList = mockApyOracle.nodesList(0);

        // update the validator list in the oracle
        this.batchUpdateNodeData(1, true);

        address firstInOracleNodesListAfter = mockApyOracle.nodesList(0);

        assertNotEq(
            firstInOracleNodesList, firstInOracleNodesListAfter, "First node in oracle nodes list should have changed"
        );

        uint256 protocolStakeAtCurrentFirst = lara.protocolTotalStakeAtValidator(firstInOracleNodesList);

        uint256 protocolStakeAtNextFirstBefore = lara.protocolTotalStakeAtValidator(firstInOracleNodesListAfter);

        assertGt(protocolStakeAtCurrentFirst, 0, "Protocol stake at first node should be bigger than zero");

        assertEq(protocolStakeAtNextFirstBefore, 0, "Protocol stake at first node should still be zero");

        lara.rebalance();

        assertEq(
            lara.protocolTotalStakeAtValidator(firstInOracleNodesList), 0, "Wrong total stake at initial validator"
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

    function testFuzz_testDoNotRedelegateStakeToMultipleValidators(uint256 amount) public {
        vm.assume(amount > 80000000 ether);
        vm.assume(amount < 800000000 ether);
        stake(amount);

        address firstInOracleNodesList = mockApyOracle.nodesList(0);

        // update the validator list in the oracle
        this.batchUpdateNodeData(1, false);

        address firstInOracleNodesListAfter = mockApyOracle.nodesList(0);

        assertEq(
            firstInOracleNodesList,
            firstInOracleNodesListAfter,
            "First node in oracle nodes list should not have changed"
        );

        uint256 protocolStakeAtCurrentFirst = lara.protocolTotalStakeAtValidator(firstInOracleNodesList);

        uint256 protocolStakeAtNextFirstBefore = lara.protocolTotalStakeAtValidator(firstInOracleNodesListAfter);

        assertEq(
            protocolStakeAtCurrentFirst,
            protocolStakeAtNextFirstBefore,
            "Validator initial delegation should be the same"
        );

        lara.rebalance();

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
