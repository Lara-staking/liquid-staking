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

contract ManyValidatorEpochTest is Test, ManyValidatorsTestSetup {
    uint256 epochDuration = 0;

    uint256[] balancesBefore;

    address[] stakers;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
        for (uint32 i = 0; i < 1000; i++) {
            stakers.push(vm.addr(i + 1));
            vm.deal(stakers[i], 500000 ether);
        }
        balancesBefore = new uint256[](stakers.length);
    }

    event ExpectedReward(uint256 expectedReward);

    function stake() public {
        for (uint32 i = 0; i < stakers.length; i++) {
            vm.prank(stakers[i]);
            lara.stake{value: 50000 ether}(50000 ether);
            assertEq(
                stTaraToken.balanceOf(stakers[i]),
                50000 ether,
                "Wrong stTARA value for staker"
            );
        }
        assertEq(
            mockDpos.getTotalDelegation(address(lara)),
            50000 ether * stakers.length,
            "MockDPOS: Wrong total stake"
        );
    }

    function run(uint8 epochNumbers) public {
        stake(); // 50 users stake 50000 ether each
        uint256 lastTreasuryBalance = 0;
        uint256 lastEpochTotalRewards = 0;
        uint256 lastEpochCommission = 0;
        uint256 totalDelegated = 50000 ether * stakers.length;

        lara.setCommission(2);
        for (uint8 j = 0; j <= epochNumbers; j++) {
            for (uint32 i = 0; i < stakers.length; i++) {
                balancesBefore[i] = stTaraToken.balanceOf(stakers[i]);
            }
            uint256 totalSupplyBefore = stTaraToken.totalSupply();
            uint256 treasuryBalanceBefore = address(lara.treasuryAddress())
                .balance;
            assertEq(
                treasuryBalanceBefore,
                lastTreasuryBalance + lastEpochCommission,
                "Wrong total treasury balance before snapshot"
            );
            lastTreasuryBalance = treasuryBalanceBefore;
            lara.snapshot();
            lara.delegateToValidators(address(lara).balance);

            assertEq(lara.lastSnapshot(), block.number, "Wrong snapshot block");

            uint256 expectedEpochReward = 100 ether + (totalDelegated / 100);
            emit ExpectedReward(expectedEpochReward);
            uint256 lastEpochExpectedCommission = (expectedEpochReward *
                lara.commission()) / 100;
            uint256 expectedDelegatorRewards = expectedEpochReward -
                lastEpochExpectedCommission;
            totalDelegated += expectedDelegatorRewards;
            assertEq(
                lara.totalDelegated(),
                totalDelegated,
                "Wrong delegated protocol value after snapshot"
            );
            assertEq(
                mockDpos.getTotalDelegation(address(lara)),
                totalDelegated,
                "DPOS: Wrong total delegation value after snapshot"
            );
            assertEq(
                address(lara.treasuryAddress()).balance,
                lastTreasuryBalance + lastEpochExpectedCommission,
                "Wrong treasury balance"
            );
            assertEq(
                address(lara).balance,
                0,
                "Wrong total Lara balance after snapshot"
            );
            for (uint32 i = 0; i < stakers.length; i++) {
                uint256 slice = Utils.calculateSlice(
                    balancesBefore[i],
                    totalSupplyBefore
                );
                uint256 currentBalance = stTaraToken.balanceOf(stakers[i]);
                uint256 expectedReward = (expectedDelegatorRewards * slice) /
                    100 /
                    1e18;
                assertEq(
                    currentBalance,
                    expectedReward + balancesBefore[i],
                    "Wrong stTara value for user after epoch end"
                );
            }
            lastEpochTotalRewards = expectedDelegatorRewards;
            lastEpochCommission = lastEpochExpectedCommission;

            vm.roll(epochDuration + lara.lastSnapshot());
        }
    }

    function testSingleEpoch() public {
        run(0);
    }

    function testRunMultipleEpochs() public {
        run(5);
    }
}
