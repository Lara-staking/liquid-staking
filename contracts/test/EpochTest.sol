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

contract SampleEpochTest is Test, TestSetup {
    uint256 epochDuration;
    uint256 stakeAmount = 5000 ether;
    uint256 totalStakes = 0;
    uint256 amountOfStakers = 100;

    uint8 firstRun = 1;
    uint8 secondRun = 5;

    uint256[] balancesBefore;

    address[] stakers;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraFactoryWithCommission(3);
        epochDuration = laraFactory.epochDuration();
    }

    function stake() public {
        for (uint32 i = 0; i < amountOfStakers; i++) {
            stakers.push(vm.addr(i + 1));
            vm.deal(stakers[i], stakeAmount * (firstRun + secondRun));
        }
        balancesBefore = new uint256[](stakers.length);
        uint256 totalDelegation = 0;
        for (uint32 i = 0; i < stakers.length; i++) {
            vm.startPrank(stakers[i]);
            address payable stakerLaraContract = laraFactory.createLara();
            Lara stakerLara = Lara(stakerLaraContract);
            stakerLara.stake{value: stakeAmount}(stakeAmount);
            totalDelegation += stakeAmount;
            vm.stopPrank();
            assertEq(
                stakerLara.commission(),
                laraFactory.commission(),
                "Wrong commission value"
            );
            assertEq(
                stTaraToken.balanceOf(stakers[i]),
                stakeAmount,
                "Wrong stTARA value for staker"
            );
            assertEq(
                mockDpos.getTotalDelegation(address(stakerLara)),
                stakeAmount,
                "MockDPOS: Wrong total stake"
            );
        }
        assertEq(
            totalDelegation,
            stakeAmount * stakers.length,
            "MockDPOS: Wrong general total stake"
        );
        totalStakes = totalDelegation;
    }

    function runTestScenario(uint8 epochNumbers) public {
        stake(); // 50 users stake 50000 ether each

        for (uint8 j = 0; j < epochNumbers; j++) {
            for (uint32 i = 0; i < stakers.length; i++) {
                balancesBefore[i] = stTaraToken.balanceOf(stakers[i]);
            }
            for (uint32 i = 0; i < laraFactory.laraInstanceCount(); i++) {
                Lara laraInstance = Lara(
                    payable(laraFactory.laraInstances(stakers[i]))
                );
                uint256 treasuryBalanceBefore = address(
                    laraFactory.treasuryAddress()
                ).balance;
                uint256 totalDelegated = laraInstance.totalDelegated();
                laraInstance.snapshot();
                uint256 newBalance = address(laraInstance).balance;
                uint256 expectedEpochReward = 100 ether + (totalStakes / 100);
                uint256 lastEpochExpectedCommission = (expectedEpochReward *
                    laraInstance.commission()) / 100;
                uint256 expectedDelegatorRewards = expectedEpochReward -
                    lastEpochExpectedCommission;
                totalDelegated += expectedDelegatorRewards;

                vm.prank(stakers[i]);
                laraInstance.delegateToValidators(newBalance);
                totalStakes += newBalance;
                assertEq(
                    laraInstance.lastSnapshot(),
                    block.number,
                    "Wrong snapshot block"
                );

                assertEq(
                    laraInstance.totalDelegated(),
                    totalDelegated,
                    "Wrong delegated protocol value after snapshot"
                );
                assertEq(
                    mockDpos.getTotalDelegation(address(laraInstance)),
                    totalDelegated,
                    "DPOS: Wrong total delegation value after snapshot"
                );
                assertEq(
                    laraFactory.treasuryAddress().balance,
                    address(laraInstance.treasuryAddress()).balance,
                    "Wrong global treasury balance after snapshot"
                );
                assertEq(
                    address(laraInstance.treasuryAddress()).balance -
                        lastEpochExpectedCommission,
                    treasuryBalanceBefore,
                    "Wrong treasury balance after snapshot"
                );
                assertEq(
                    address(laraInstance).balance,
                    0,
                    "Wrong total Lara balance after compound"
                );
            }
            vm.roll(
                epochDuration +
                    Lara(payable(laraFactory.laraInstances(stakers[0])))
                        .lastSnapshot()
            );
        }
    }

    function testSingleEpoch() public {
        runTestScenario(firstRun);
    }

    function testRunMultipleEpochs() public {
        runTestScenario(secondRun);
    }
}
