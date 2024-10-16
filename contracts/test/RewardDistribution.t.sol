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
import {
    StakeAmountTooLow,
    SnapshotAlreadyClaimed,
    SnapshotNotFound,
    NoDelegation,
    ZeroAddress
} from "@contracts/libs/SharedErrors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract UniPool {
    StakedNativeAsset wstTARA;

    constructor(StakedNativeAsset _wstTARA) {
        wstTARA = _wstTARA;
    }

    function deposit(uint256 amount) public {
        // take wstTARA from user
        wstTARA.transferFrom(msg.sender, address(this), amount);
        // do nothing
    }
}

contract RewardDistributionTest is Test, TestSetup {
    uint256 epochDuration = 0;

    uint256[] balancesBefore;

    address[] stakers;

    uint256 stakedAmount = 50000 ether;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraWithCommission(8);
        epochDuration = lara.epochDuration();
        for (uint32 i = 0; i < 1000; i++) {
            stakers.push(vm.addr(i + 1));
            vm.deal(stakers[i], 5000000 ether);
        }
        balancesBefore = new uint256[](stakers.length);
    }

    event ExpectedReward(uint256 expectedReward);
    event ExcessReward(uint256 excessReward);
    event Discount(uint32 discount);

    function stake(bool withCommissionsDiscounts, uint256 noOfStakers) public {
        for (uint32 i = 0; i < noOfStakers; i++) {
            if (withCommissionsDiscounts) {
                lara.setCommissionDiscounts(stakers[i], (i % 10));
                assertEq(lara.commissionDiscounts(stakers[i]), (i % 10), "Wrong commission discount");
            }
            vm.prank(stakers[i]);
            lara.stake{value: stakedAmount}(stakedAmount);
            assertEq(stTaraToken.balanceOf(stakers[i]), stakedAmount, "Wrong stTARA value for staker");
        }
        assertEq(mockDpos.getTotalDelegation(address(lara)), 50000 ether * noOfStakers, "MockDPOS: Wrong total stake");
    }

    function checkRewardsAreRight(address singleStaker, uint256 snapshotId, uint256 initialBalance) public {
        if (initialBalance > 0) {
            uint256 totalSupplyAtSnapshot = stTaraToken.totalSupplyAt(snapshotId);
            assertEq(totalSupplyAtSnapshot, initialBalance, "Wrong total supply at snapshot");
        }

        uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);
        assertTrue(rewardsPerSnapshot > 0, "Rewards per snapshot should be greater than 0");

        assertFalse(lara.stakerSnapshotClaimed(singleStaker, snapshotId), "Staker snapshot claimed should be false");

        lara.distributeRewardsForSnapshot(singleStaker, snapshotId);

        if (initialBalance > 0) {
            assertTrue(lara.stakerSnapshotClaimed(singleStaker, snapshotId), "Staker snapshot claimed should be true");

            uint256 newBalance = stTaraToken.cumulativeBalanceOf(singleStaker);
            assertEq(
                newBalance, initialBalance + rewardsPerSnapshot, "Wrong balance of staker after reward distribution"
            );
        }
    }

    function test_Reverts_On_DoubleClaim() public {
        address singleStaker = vm.addr(6666666666);
        uint256 initialBalance = 50000 ether;
        vm.deal(singleStaker, initialBalance);
        vm.prank(singleStaker);
        lara.stake{value: initialBalance}(initialBalance);

        uint256 snapshotId = lara.snapshot();

        checkRewardsAreRight(singleStaker, snapshotId, stTaraToken.cumulativeBalanceOfAt(singleStaker, snapshotId));

        vm.expectRevert(abi.encodeWithSelector(SnapshotAlreadyClaimed.selector, snapshotId, singleStaker));
        lara.distributeRewardsForSnapshot(singleStaker, snapshotId);
    }

    function test_Reverts_On_DisributeRewards_Check_Violation() public {
        address singleStaker = vm.addr(6666666666);

        vm.expectRevert(abi.encodeWithSelector(NoDelegation.selector));
        lara.snapshot();

        uint256 initialBalance = 50000 ether;
        vm.deal(singleStaker, initialBalance);
        vm.prank(singleStaker);
        lara.stake{value: initialBalance}(initialBalance);

        uint256 snapshotId = lara.snapshot();

        checkRewardsAreRight(singleStaker, snapshotId, stTaraToken.cumulativeBalanceOfAt(singleStaker, snapshotId));

        vm.expectRevert(abi.encodeWithSelector(SnapshotNotFound.selector, snapshotId + 1));
        lara.distributeRewardsForSnapshot(singleStaker, snapshotId + 1);

        vm.expectRevert(abi.encodeWithSelector(ZeroAddress.selector));
        lara.distributeRewardsForSnapshot(address(0), snapshotId);
    }

    function test_OneStake_ThenDeposit_In_NonYieldBearing_Contract_NoDoubleRewards() public {
        address singleStaker = vm.addr(6666666666);
        uint256 initialBalance = 50000 ether;
        vm.deal(singleStaker, initialBalance);
        vm.prank(singleStaker);
        lara.stake{value: initialBalance}(initialBalance);

        // Then deposit wstTARA into Uni v3 pool
        vm.startPrank(singleStaker);
        UniPool uniPool = new UniPool(stTaraToken);
        stTaraToken.approve(address(uniPool), initialBalance);
        uniPool.deposit(initialBalance);
        vm.stopPrank();

        uint256 stTaraTotalSupplyBefore = stTaraToken.totalSupply();

        uint256 snapshotId = lara.snapshot();

        uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);

        checkRewardsAreRight(singleStaker, snapshotId, stTaraToken.cumulativeBalanceOfAt(singleStaker, snapshotId));

        checkRewardsAreRight(
            address(stTaraToken), snapshotId, stTaraToken.cumulativeBalanceOfAt(address(stTaraToken), snapshotId)
        );

        checkRewardsAreRight(
            address(uniPool), snapshotId, stTaraToken.cumulativeBalanceOfAt(address(uniPool), snapshotId)
        );

        uint256 stTaraTotalSupplyAfter = stTaraToken.totalSupply();

        assertEq(
            stTaraTotalSupplyBefore + rewardsPerSnapshot, stTaraTotalSupplyAfter, "Wrong total supply after snapshot"
        );
    }

    function test_OneStake_ThenDeposit_In_YieldBearing_Contract_NoDoubleRewards() public {
        address singleStaker = vm.addr(6666666666);
        uint256 initialBalance = 50000 ether;
        vm.deal(singleStaker, initialBalance);
        vm.prank(singleStaker);
        lara.stake{value: initialBalance}(initialBalance);

        UniPool uniPool = new UniPool(stTaraToken);
        // Set yield bearing contract
        stTaraToken.setYieldBearingContract(address(uniPool));
        // Then deposit wstTARA into Uni v3 pool
        vm.startPrank(singleStaker);
        stTaraToken.approve(address(uniPool), initialBalance);
        uniPool.deposit(initialBalance);
        vm.stopPrank();

        uint256 stTaraTotalSupplyBefore = stTaraToken.totalSupply();

        uint256 snapshotId = lara.snapshot();

        uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);

        checkRewardsAreRight(singleStaker, snapshotId, stTaraToken.cumulativeBalanceOfAt(singleStaker, snapshotId));

        checkRewardsAreRight(
            address(stTaraToken), snapshotId, stTaraToken.cumulativeBalanceOfAt(address(stTaraToken), snapshotId)
        );

        checkRewardsAreRight(
            address(uniPool), snapshotId, stTaraToken.cumulativeBalanceOfAt(address(uniPool), snapshotId)
        );

        uint256 stTaraTotalSupplyAfter = stTaraToken.totalSupply();

        assertEq(
            stTaraTotalSupplyBefore + rewardsPerSnapshot, stTaraTotalSupplyAfter, "Wrong total supply after snapshot"
        );
    }

    function test_OneStake_OneEpoch_RewardDistribution() public {
        address singleStaker = vm.addr(6666666666);
        uint256 initialBalance = 50000 ether;
        vm.deal(singleStaker, initialBalance);
        vm.prank(singleStaker);
        lara.stake{value: initialBalance}(initialBalance);
        uint256 snapshotId = lara.snapshot();

        uint256 balanceOfStakerAtSnapshot = stTaraToken.cumulativeBalanceOfAt(singleStaker, snapshotId);

        assertEq(balanceOfStakerAtSnapshot, initialBalance, "Wrong balance of staker at snapshot");

        uint256 totalSupplyAtSnapshot = stTaraToken.totalSupplyAt(snapshotId);
        assertEq(totalSupplyAtSnapshot, initialBalance, "Wrong total supply at snapshot");

        uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);
        assertTrue(rewardsPerSnapshot > 0, "Rewards per snapshot should be greater than 0");

        assertFalse(lara.stakerSnapshotClaimed(singleStaker, snapshotId), "Staker snapshot claimed should be false");

        lara.distributeRewardsForSnapshot(singleStaker, snapshotId);

        assertTrue(lara.stakerSnapshotClaimed(singleStaker, snapshotId), "Staker snapshot claimed should be true");

        uint256 newBalance = stTaraToken.cumulativeBalanceOf(singleStaker);
        assertEq(newBalance, initialBalance + rewardsPerSnapshot, "Wrong balance of staker after reward distribution");
    }

    function test_stTARA_OneStake_OneEpoch_RewardDistribution() public {
        address singleStaker = vm.addr(6666666666);
        uint256 initialBalance = 50000 ether;
        vm.deal(singleStaker, initialBalance);
        vm.prank(singleStaker);
        lara.stake{value: initialBalance}(initialBalance);

        uint256 snapshotId = lara.snapshot();

        uint256 balanceOfStakerAtSnapshot = stTaraToken.cumulativeBalanceOfAt(singleStaker, snapshotId);

        assertEq(balanceOfStakerAtSnapshot, initialBalance, "Wrong balance of staker at snapshot");

        uint256 totalSupplyAtSnapshot = stTaraToken.totalSupplyAt(snapshotId);
        assertEq(totalSupplyAtSnapshot, initialBalance, "Wrong total supply at snapshot");

        uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);
        assertTrue(rewardsPerSnapshot > 0, "Rewards per snapshot should be greater than 0");

        assertFalse(lara.stakerSnapshotClaimed(singleStaker, snapshotId), "Staker snapshot claimed should be false");

        lara.distributeRewardsForSnapshot(singleStaker, snapshotId);

        assertTrue(lara.stakerSnapshotClaimed(singleStaker, snapshotId), "Staker snapshot claimed should be true");

        uint256 newBalance = stTaraToken.cumulativeBalanceOf(singleStaker);
        assertEq(newBalance, initialBalance + rewardsPerSnapshot, "Wrong balance of staker after reward distribution");
    }

    function testFuzz_some_stTARA_MultipleStakes_withDiscounts(uint32 noOfStakers) public {
        vm.assume(noOfStakers > 0 && noOfStakers < 100);
        stake(true, noOfStakers);

        uint256 snapshotId = lara.snapshot();

        uint256 totalSupplyAtSnapshot = stTaraToken.totalSupplyAt(snapshotId);
        assertEq(totalSupplyAtSnapshot, stakedAmount * noOfStakers, "Wrong total supply at snapshot");

        for (uint32 i = 0; i < noOfStakers; i++) {
            uint256 balanceOfStakerAtSnapshot = stTaraToken.cumulativeBalanceOfAt(stakers[i], snapshotId);
            assertEq(balanceOfStakerAtSnapshot, stakedAmount, "Wrong balance of staker at snapshot");
            assertFalse(lara.stakerSnapshotClaimed(stakers[i], snapshotId), "Staker snapshot claimed should be false");

            // Distribute rewards
            lara.distributeRewardsForSnapshot(stakers[i], snapshotId);

            assertTrue(lara.stakerSnapshotClaimed(stakers[i], snapshotId), "Staker snapshot claimed should be true");

            uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);
            assertTrue(rewardsPerSnapshot > 0, "Rewards per snapshot should be greater than 0");

            uint256 newBalance = stTaraToken.cumulativeBalanceOf(stakers[i]);

            assertTrue(newBalance > stakedAmount, "Wrong balance of staker after reward distribution");

            uint256 slice = calculateSlice(balanceOfStakerAtSnapshot, totalSupplyAtSnapshot);
            emit SliceParts(balanceOfStakerAtSnapshot, totalSupplyAtSnapshot);
            uint256 delegatorReward = slice * rewardsPerSnapshot / 1e18;
            emit GeneralParts(slice, rewardsPerSnapshot);
            uint256 commissionDiscount = (delegatorReward * lara.commissionDiscounts(stakers[i])) / 100;
            uint256 delegatorRewardWithCommission = delegatorReward + commissionDiscount;
            emit RewardParts(
                balanceOfStakerAtSnapshot,
                delegatorReward,
                lara.commissionDiscounts(stakers[i]),
                commissionDiscount,
                delegatorRewardWithCommission
            );
            assertEq(
                newBalance,
                balanceOfStakerAtSnapshot + delegatorRewardWithCommission,
                // 1e4,
                "Wrong balance of staker after reward distribution"
            );

            uint256 totalSupply = stTaraToken.totalSupply();
            assertTrue(
                totalSupply > totalSupplyAtSnapshot, "Total current supply should be greater than snapshot supply"
            );
        }
    }

    event RewardParts(
        uint256 balanceBefore,
        uint256 generalPart,
        uint256 commissionMultiplier,
        uint256 commissionPart,
        uint256 totalReward
    );

    event GeneralParts(uint256 slice, uint256 snapshotRewards);

    event SliceParts(uint256 delegatorBalance, uint256 stTaraSupply);

    function test_some_stTara() public {
        uint32 noOfStakers = 10;
        stake(true, noOfStakers);

        uint256 snapshotId = lara.snapshot();

        uint256 totalSupplyAtSnapshot = stTaraToken.totalSupplyAt(snapshotId);
        assertEq(totalSupplyAtSnapshot, stakedAmount * noOfStakers, "Wrong total supply at snapshot");

        for (uint32 i = 0; i < noOfStakers; i++) {
            uint256 balanceOfStakerAtSnapshot = stTaraToken.cumulativeBalanceOfAt(stakers[i], snapshotId);
            assertEq(balanceOfStakerAtSnapshot, stakedAmount, "Wrong balance of staker at snapshot");
            assertFalse(lara.stakerSnapshotClaimed(stakers[i], snapshotId), "Staker snapshot claimed should be false");

            // Distribute rewards
            lara.distributeRewardsForSnapshot(stakers[i], snapshotId);

            assertTrue(lara.stakerSnapshotClaimed(stakers[i], snapshotId), "Staker snapshot claimed should be true");

            uint256 rewardsPerSnapshot = lara.rewardsPerSnapshot(snapshotId);
            assertTrue(rewardsPerSnapshot > 0, "Rewards per snapshot should be greater than 0");

            uint256 newBalance = stTaraToken.cumulativeBalanceOf(stakers[i]);

            assertTrue(newBalance > stakedAmount, "Wrong balance of staker after reward distribution");

            uint256 slice = calculateSlice(balanceOfStakerAtSnapshot, totalSupplyAtSnapshot);
            emit SliceParts(balanceOfStakerAtSnapshot, totalSupplyAtSnapshot);
            uint256 delegatorReward = slice * rewardsPerSnapshot / 1e18;
            emit GeneralParts(slice, rewardsPerSnapshot);
            uint256 commissionDiscount = (delegatorReward / 100) * lara.commissionDiscounts(stakers[i]);
            uint256 delegatorRewardWithCommission = delegatorReward + commissionDiscount;
            emit RewardParts(
                balanceOfStakerAtSnapshot,
                delegatorReward,
                lara.commissionDiscounts(stakers[i]),
                commissionDiscount,
                delegatorRewardWithCommission
            );
            assertEq(
                newBalance,
                balanceOfStakerAtSnapshot + delegatorRewardWithCommission,
                // 1e4,
                "Wrong balance of staker after reward distribution"
            );

            uint256 totalSupply = stTaraToken.totalSupply();
            assertTrue(
                totalSupply > totalSupplyAtSnapshot, "Total current supply should be greater than snapshot supply"
            );
        }
    }
}
