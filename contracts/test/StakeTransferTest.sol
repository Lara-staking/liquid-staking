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
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";

contract StakeTransferTest is Test, TestSetup {
    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraFactoryWithCommission(3);
    }

    function testFuzz_anyAddressCanCreateLara(address sample) public {
        vm.assume(sample != address(0));
        vm.prank(sample);
        address payable laraContract = laraFactory.createLara();
        Lara laraC = Lara(laraContract);
        assertEq(laraC.owner(), address(laraFactory.owner()), "Wrong owner");
        assertEq(laraC.delegator(), sample, "Wrong delegator");
        assertEq(
            laraFactory.laraInstances(sample),
            laraContract,
            "Wrong lara instance"
        );
        assertEq(laraC.stakeOf(sample), 0, "Stake should be 0");

        // sample staker stakes 10k TARA
        uint256 initialStake = 10000 ether;
        vm.deal(sample, initialStake);
        vm.prank(sample);
        laraC.stake{value: initialStake}(initialStake);
        assertEq(laraC.stakeOf(sample), initialStake, "Stake should be 10k");
        assertEq(laraC.owners(0), sample, "Owner should be sample");

        vm.roll(laraC.lastSnapshot() + laraC.epochDuration());
        // we make a snapshot and staker get the full amount of rewards
        laraC.snapshot();
        uint256 totalEpochRewards = 100 ether + laraC.totalDelegated() / 100;
        uint256 expectedReward = (totalEpochRewards) -
            ((totalEpochRewards * laraC.commission()) / 100);
        assertEq(
            stTaraToken.balanceOf(sample),
            initialStake + expectedReward,
            "Rewards should be 10k + 100 % staking reward"
        );

        // SCENARIO 1: Staker 2 comes and buys 5k stTARA
        address staker2 = vm.addr(666);
        uint256 halfStake = initialStake / 2;
        vm.prank(sample);
        stTaraToken.transfer(staker2, halfStake);

        //check stakeOf for both
        assertEq(laraC.owners(1), staker2, "Owner should be staker2");
        assertEq(laraC.stakeOf(sample), halfStake, "Stake should be half");
        assertEq(laraC.stakeOf(staker2), halfStake, "Stake should be half");
        assertEq(
            stTaraToken.balanceOf(sample),
            halfStake + expectedReward + expectedReward,
            "stTARA balance should be 5k + 100 % staking reward"
        );
        assertEq(
            stTaraToken.balanceOf(staker2),
            halfStake,
            "stTARA balance should be 5k"
        );
        // we do a roll + snapshot and check the rewards
        vm.roll(laraC.lastSnapshot() + laraC.epochDuration());
        laraC.snapshot();

        uint256 totalEpochRewards2 = 100 ether + laraC.totalDelegated() / 100;
        uint256 expectedReward2 = (totalEpochRewards2) -
            ((totalEpochRewards2 * laraC.commission()) / 100);
        assertEq(
            stTaraToken.balanceOf(staker2),
            halfStake + expectedReward2 / 2,
            "Rewards should be 5k + 50 % current reward"
        );
        assertEq(
            stTaraToken.balanceOf(sample),
            halfStake + expectedReward + expectedReward + expectedReward2 / 2,
            "Rewards should be 5k + 100% previous reward + 100% previous reward(BECAUSE OF TRANSFER) + 50 % current reward"
        );
    }
}
