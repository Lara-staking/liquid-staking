// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "../interfaces/IApyOracle.sol";
import {Lara} from "../Lara.sol";
import {ApyOracle} from "../ApyOracle.sol";
import {MockDpos} from "../mocks/MockDpos.sol";
import {StakedNativeAsset} from "../StakedNativeAsset.sol";
import {TestSetup} from "./SetUpTest.sol";
import {Utils} from "../libs/Utils.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract SimpleEpochTest is Test, TestSetup {
    uint256 epochDuration = 0;

    uint256[] balancesBefore;

    address[] stakers;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
        for (uint32 i = 0; i < 5; i++) {
            stakers.push(vm.addr(i + 1));
            vm.deal(stakers[i], 5000000 ether);
        }
        balancesBefore = new uint256[](stakers.length);
    }

    event ExpectedReward(uint256 expectedReward);
    event ExcessReward(uint256 excessReward);
    event Discount(uint32 discount);

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

    event BalanceParts(uint256 currentBalance, uint256 expectedReward, uint256 balanceBefore);

    function run(uint8 epochNumbers) public {
        stake(false); // 50 users stake 50000 ether each
        uint256 lastTreasuryBalance = 0;
        uint256 lastEpochTotalRewards = 0;
        uint256 totalDelegated = 50000 ether * stakers.length;

        lara.setCommission(6);
        for (uint8 j = 0; j <= epochNumbers; j++) {
            for (uint32 i = 0; i < stakers.length; i++) {
                balancesBefore[i] = stTaraToken.balanceOf(stakers[i]);
            }
            uint256 totalSupplyBefore = stTaraToken.totalSupply();
            lastTreasuryBalance = address(lara.treasuryAddress()).balance;
            uint256 snapshotId = lara.snapshot();

            assertEq(totalSupplyBefore, stTaraToken.totalSupplyAt(snapshotId), "Wrong total supply at snapshot");

            for (uint32 i = 0; i < stakers.length; i++) {
                lara.distrbuteRewardsForSnapshot(stakers[i], snapshotId);
            }
            lara.compound(address(lara).balance);

            assertEq(lara.lastSnapshotBlock(), block.number, "Wrong snapshot block");

            uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);

            emit ExpectedReward(rewardsPerSnapshot);

            totalDelegated += rewardsPerSnapshot;
            assertEq(
                mockDpos.getTotalDelegation(address(lara)),
                totalDelegated,
                "DPOS: Wrong total delegation value after snapshot"
            );
            assertEq(address(lara).balance, 0, "Wrong total Lara balance after snapshot");
            for (uint32 i = 0; i < stakers.length; i++) {
                uint256 slice = Utils.calculateSlice(balancesBefore[i], totalSupplyBefore);
                uint256 delegatorReward = slice * rewardsPerSnapshot / 1e18;
                uint256 commissionPart = (delegatorReward / 100) * lara.commissionDiscounts(stakers[i]);

                uint256 currentBalance = stTaraToken.balanceOf(stakers[i]);
                uint256 expectedReward = delegatorReward + commissionPart;
                emit BalanceParts(currentBalance, expectedReward, balancesBefore[i]);
                assertEq(
                    currentBalance, expectedReward + balancesBefore[i], "Wrong stTara value for user after epoch end"
                );
            }
            lastEpochTotalRewards = rewardsPerSnapshot;

            vm.roll(epochDuration + lara.lastSnapshotBlock());
        }
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

            assertEq(lara.lastSnapshotBlock(), block.number, "Wrong snapshot block");

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

                emit StakerRewardDetails(i, slice, commissionDiscount, delegatorRewardWithCommission, actualReward);

                assertEq(
                    currentBalance,
                    delegatorRewardWithCommission + balancesBefore[i],
                    string(abi.encodePacked("Wrong stTara value for user ", Strings.toString(i), " after epoch end"))
                );
            }

            emit RewardSummary(expectedDelegatorRewards, totalExpectedRewardsWithDiscounts, totalActualRewards);

            // Check if total rewards distributed match expected rewards (allowing for small rounding differences)
            assertApproxEqAbs(
                totalActualRewards,
                totalExpectedRewardsWithDiscounts,
                stakers.length, // Allow for 1 wei rounding error per staker
                "Total actual rewards don't match total expected rewards with discounts"
            );

            lastEpochTotalRewards = expectedDelegatorRewards;
            lastEpochCommission = lastEpochExpectedCommission;

            vm.roll(epochDuration + lara.lastSnapshotBlock());
        }
    }

    event StakerRewardDetails(
        uint32 stakerIndex, uint256 slice, uint256 discount, uint256 expectedReward, uint256 actualReward
    );
    event RewardSummary(
        uint256 expectedDelegatorRewards, uint256 totalExpectedRewardsWithDiscounts, uint256 totalActualRewards
    );

    function test_simpleCommissionMaths() public pure {
        uint256 commission = 6;
        uint256 epochRewards = 4431 ether;
        uint256 epochCommission = (epochRewards * commission) / 100;
        uint256 distributableRewards = epochRewards - epochCommission;
        assertEq(epochRewards, distributableRewards + epochCommission, "Wrong distributable rewards");
        uint256 slice = Utils.calculateSlice(100 ether, 100 ether);
        assertEq(slice, 1 ether, "Wrong slice value");
    }

    function test_SingleEpoch() public {
        run(0);
    }

    function test_RunMultipleEpochs() public {
        run(5);
    }

    function test_CommissionDiscounts() public {
        runWithDiscounts(0);
    }
}
