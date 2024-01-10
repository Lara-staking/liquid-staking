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

contract EpochTest is Test, TestSetup {
    uint256 epochDuration = 0;

    address[] stakers;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
        for (uint32 i = 0; i < 10; i++) {
            stakers.push(vm.addr(i + 1));
            vm.deal(stakers[i], 500000 ether);
        }
    }

    function startAndEndEpoch(uint8 epochNumbers) public {
        // 50 users stake 50000 ether each
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
            address(lara).balance,
            50000 ether * stakers.length,
            "Wrong total balance"
        );

        Utils.HolderData[] memory epochEndData;
        uint256 lastTreasuryBalance = 0;
        uint256 lastEpochTotalRewards = 0;
        uint256 lastEpochCommission = 0;
        uint256 totalDelegated = 0;

        lara.setCommission(2);
        for (uint8 j = 0; j <= epochNumbers; j++) {
            lara.startEpoch();
            Utils.HolderData[] memory holderData = stTaraToken
                .getHolderSnapshot();
            for (uint32 i = 0; i < holderData.length; i++) {
                if (j == 0) {
                    assertEq(
                        holderData[i].amount,
                        50000 ether,
                        "Wrong stTara value for user after epoch start"
                    );
                } else {
                    assertEq(
                        epochEndData[i].amount,
                        holderData[i].amount,
                        "Wrong stTara value for user after epoch start in secondary iterations"
                    );
                }
            }

            if (j == 0) {
                totalDelegated = 50000 ether * stakers.length;
            } else {
                totalDelegated = totalDelegated + lastEpochTotalRewards;
            }

            assertEq(
                lara.lastEpochTotalDelegated(),
                totalDelegated,
                "Wrong delegated protocol value after epoch start"
            );

            assertEq(
                address(lara).balance,
                totalDelegated - lara.lastEpochTotalDelegated(),
                "Wrong total Lara balance after epoch start"
            );

            assertEq(
                mockDpos.getTotalDelegation(address(lara)),
                totalDelegated,
                "DPOS: Wrong total delegation value after epoch start"
            );
            assertTrue(
                lara.isEpochRunning(),
                "Epoch should be running after epoch start"
            );
            assertEq(
                lara.lastEpochStartBlock(),
                block.number,
                "Wrong epoch start block"
            );

            vm.roll(epochDuration + lara.lastEpochStartBlock());
            uint256 totalSupplyBefore = stTaraToken.totalSupply();
            uint256 treasuryBalanceBefore = address(lara.treasuryAddress())
                .balance;
            assertEq(
                treasuryBalanceBefore,
                lastTreasuryBalance + lastEpochCommission,
                "Wrong total Lara balance before epoch end"
            );
            lara.endEpoch();
            lastTreasuryBalance = treasuryBalanceBefore;

            Utils.HolderData[] memory holderSlices = new Utils.HolderData[](
                holderData.length
            );
            for (uint32 i = 0; i < holderData.length; i++) {
                uint256 slice = Utils.calculateSlice(
                    holderData[i].amount,
                    totalSupplyBefore
                );
                holderSlices[i] = Utils.HolderData({
                    holder: holderData[i].holder,
                    amount: slice
                });
            }
            uint256 expectedEpochReward = (100 ether +
                lara.lastEpochTotalDelegated() /
                100);
            uint256 lastEpochExpectedCommission = (expectedEpochReward * 2) /
                100;
            uint256 expectedDelegatorRewards = expectedEpochReward -
                lastEpochExpectedCommission;

            assertEq(
                address(lara.treasuryAddress()).balance,
                lastTreasuryBalance + lastEpochExpectedCommission,
                "Wrong treasury balance"
            );
            // check if the rewards were calculated correctly
            for (uint32 i = 0; i < holderSlices.length; i++) {
                uint256 currentBalance = stTaraToken.balanceOf(
                    holderSlices[i].holder
                );
                uint256 expectedReward = (expectedDelegatorRewards *
                    holderSlices[i].amount) /
                    100 /
                    1e18;
                assertEq(
                    currentBalance,
                    expectedReward + holderData[i].amount,
                    "Wrong stTara value for user after epoch end"
                );
            }
            stTaraToken.makeHolderSnapshot();
            epochEndData = stTaraToken.getHolderSnapshot();
            lastEpochTotalRewards = expectedDelegatorRewards;
            lastEpochCommission = lastEpochExpectedCommission;
        }
    }

    function testSingleEpoch() public {
        startAndEndEpoch(0);
    }

    function testFuzz_runMultipleEpochs(uint8 epochNumber) public {
        vm.assume(epochNumber > 0);
        vm.assume(epochNumber < 255);
        startAndEndEpoch(epochNumber);
    }
}
