// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "@contracts/interfaces/IApyOracle.sol";
import {Lara} from "@contracts/Lara.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";
import {MockDpos} from "@contracts/mocks/MockDpos.sol";
import {StakedNativeAsset} from "@contracts/StakedNativeAsset.sol";
import {TestSetup} from "@contracts/test/SetUp.t.sol";
import {StakeAmountTooLow} from "@contracts/libs/SharedErrors.sol";

contract RebalanceTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function test_changeOwner2Step() public {
        address newOwner = address(1234);
        lara.transferOwnership(newOwner);
        address ownerBefore = lara.owner();
        assertEq(ownerBefore, address(this), "Owner should be the same as the caller");
        vm.prank(newOwner);
        lara.acceptOwnership();
        address ownerAfter = lara.owner();
        assertEq(ownerAfter, newOwner, "Owner should be the new owner");
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

        // start the epoch
        lara.snapshot();

        vm.roll(lara.lastSnapshotBlock() + lara.epochDuration());
    }

    // ReDelegate from
    function testFuzz_testRedelegateStakeToSingleValidator(uint256 amount) public {
        vm.assume(amount < 80000000 ether);
        stake(amount);
        // re-delegate the total stake from one validator to another
        address validator1 = findValidatorWithStake(amount);
        // address validator2 = validators[validators.length - 1];
        uint256 totalSupplyBefore = stTaraToken.totalSupply();
        lara.rebalance();

        // check that the stake value didn't change
        assertEq(stTaraToken.totalSupply(), totalSupplyBefore, "ReDelegate: Wrong delegated amount");

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
