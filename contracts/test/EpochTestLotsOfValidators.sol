// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "../interfaces/IApyOracle.sol";
import {Lara} from "../Lara.sol";
import {ApyOracle} from "../ApyOracle.sol";
import {MockDpos} from "../mocks/MockDpos.sol";
import {StakedNativeAsset} from "../StakedNativeAsset.sol";
import {Utils} from "../libs/Utils.sol";
import {ManyValidatorsTestSetup} from "./SetUpTestLotsOfValidators.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";
import {SimpleEpochTest} from "./EpochTest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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

    function stake(bool withCommissionsDiscounts) public {
        for (uint32 i = 0; i < stakers.length; i++) {
            if (withCommissionsDiscounts) {
                lara.setCommissionDiscounts(stakers[i], i % 10);
            }
            vm.prank(stakers[i]);
            lara.stake{value: 50000 ether}(50000 ether);
            assertEq(stTaraToken.balanceOf(stakers[i]), 50000 ether, "Wrong stTARA value for staker");
        }
        assertEq(
            mockDpos.getTotalDelegation(address(lara)), 50000 ether * stakers.length, "MockDPOS: Wrong total stake"
        );
    }

    function runWithDiscounts(uint8 epochNumbers) public {
        stake(true); // 50 users stake 50000 ether each
        uint256 lastTreasuryBalance = 0;
        uint256 lastEpochTotalRewards = 0;
        uint256 lastEpochCommission = 0;
        uint256 totalDelegated = 50000 ether * stakers.length;

        lara.setCommission(6);

        for (uint8 j = 0; j <= epochNumbers; j++) {
            for (uint32 i = 0; i < stakers.length; i++) {
                balancesBefore[i] = stTaraToken.balanceOf(stakers[i]);
            }
            uint256 totalSupplyBefore = stTaraToken.totalSupply();
            uint256 treasuryBalanceBefore = address(lara.treasuryAddress()).balance;
            assertEq(
                treasuryBalanceBefore,
                lastTreasuryBalance + lastEpochCommission,
                "Wrong total treasury balance before snapshot"
            );
            lastTreasuryBalance = treasuryBalanceBefore;
            uint256 snapshotId = lara.snapshot();

            for (uint32 i = 0; i < stakers.length; i++) {
                lara.distrbuteRewardsForSnapshot(stakers[i], snapshotId);
            }

            lara.delegateToValidators(address(lara).balance);

            uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);

            assertEq(lara.lastSnapshot(), block.number, "Wrong snapshot block");

            uint256 expectedEpochReward = 100 ether + (totalDelegated / 100);
            emit ExpectedReward(expectedEpochReward);
            uint256 lastEpochExpectedCommission = (expectedEpochReward * lara.commission()) / 100;
            uint256 expectedDelegatorRewards = expectedEpochReward - lastEpochExpectedCommission;
            totalDelegated += expectedDelegatorRewards;

            uint256 totalActualRewards = 0;
            uint256 totalExpectedRewardsWithDiscounts = 0;
            for (uint32 i = 0; i < stakers.length; i++) {
                uint256 slice = Utils.calculateSlice(balancesBefore[i], totalSupplyBefore);
                uint256 delegatorReward = slice * rewardsPerSnapshot / 1e18;
                uint256 commissionDiscount = (delegatorReward / 100) * lara.commissionDiscounts(stakers[i]);
                uint256 delegatorRewardWithCommission = delegatorReward + commissionDiscount;

                uint256 currentBalance = stTaraToken.balanceOf(stakers[i]);
                uint256 actualReward = currentBalance - balancesBefore[i];

                totalActualRewards += actualReward;
                totalExpectedRewardsWithDiscounts += delegatorRewardWithCommission;

                assertEq(
                    currentBalance,
                    delegatorRewardWithCommission + balancesBefore[i],
                    string(abi.encodePacked("Wrong stTara value for user ", Strings.toString(i), " after epoch end"))
                );
            }

            // Check if total rewards distributed match expected rewards (allowing for small rounding differences)
            assertApproxEqAbs(
                totalActualRewards,
                totalExpectedRewardsWithDiscounts,
                stakers.length, // Allow for 1 wei rounding error per staker
                "Total actual rewards don't match total expected rewards with discounts"
            );

            lastEpochTotalRewards = expectedDelegatorRewards;
            lastEpochCommission = lastEpochExpectedCommission;

            vm.roll(epochDuration + lara.lastSnapshot());
        }
    }

    function test_SingleEpoch() public {
        runWithDiscounts(0);
    }

    function test_RunMultipleEpochs() public {
        runWithDiscounts(5);
    }
}
