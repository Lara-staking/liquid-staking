// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@contracts/LaraStaking.sol";
import "@contracts/LaraToken.sol";
import "@contracts/veLara.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LaraStakeV2} from "@contracts/test/utils/LaraStakeV2.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {console} from "forge-std/console.sol";

contract LaraStakingTestSuite is Test {
    LaraStaking stakingContract;
    veLara rewardToken;
    LaraToken stakingToken;
    address user = address(0x123);
    address treasury = address(0x789);

    uint256 BLOCK_TIME = 4; //seconds
    uint256 SECONDS_PER_YEAR = 365 * 24 * 60 * 60;

    uint256 APY = 13; // 13% APY
    uint256 MATURITY_BLOCK_COUNT = 426445; // 6 months
    uint256 STAKED_AMOUNT = 100 ether;

    function setUp() public {
        stakingToken = new LaraToken(treasury);
        rewardToken = new veLara(address(stakingToken));
        assertEq(
            rewardToken.balanceOf(address(this)),
            1000000 ether,
            "Deployer should have 100M veLARA"
        );

        address stakingContractProxy = Upgrades.deployUUPSProxy(
            "LaraStaking.sol",
            abi.encodeCall(
                LaraStaking.initialize,
                (
                    address(rewardToken),
                    address(stakingToken),
                    1,
                    4530,
                    11e11,
                    426445 // 6 months
                )
            )
        );

        stakingContract = LaraStaking(payable(stakingContractProxy));

        // add 1M LARA to the staking contract
        rewardToken.approve(address(stakingContract), 1000000 ether);
        stakingContract.depositRewardTokens(1000000 ether);

        // send 10M LARA to user
        stakingToken.transfer(user, 10000000 ether);
        assertEq(
            stakingToken.balanceOf(user),
            10000000 ether,
            "User should have 10M LARA"
        );
    }

    /* Unhappy flow */

    // User tries to stake without approving the staking amount
    function test_StakeWithoutApproving() public {
        vm.startPrank(user);
        vm.expectRevert();
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();
    }

    // Claim rewards before staking
    function test_ClaimRewardsBeforeStaking() public {
        vm.startPrank(user);
        vm.expectRevert("No rewards");
        stakingContract.claimRewards();
        vm.stopPrank();
    }

    // Stake amount exceeds user balance
    function test_StakeAmountExceedsUserBlance() public {
        vm.startPrank(user);
        uint256 invalidStakeAmount = stakingToken.balanceOf(user) + 1; // More than the user's balance
        stakingToken.approve(address(stakingContract), invalidStakeAmount);
        vm.expectRevert();
        stakingContract.stake(invalidStakeAmount);
        vm.stopPrank();
    }

    // Claim rewards immediately after staking
    function test_ClaimRewardsImmediatelyAfterStaking() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // attempt to claim rewards immediately after staking (should be zero)
        vm.prank(user);
        vm.expectRevert("No rewards");
        stakingContract.claimRewards();
    }

    // Redeem without claiming rewards first
    function test_RedeemWithoutClaimingRewardsFirst() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(1);
    }

    // Stake, Claim, Redeem Successfully
    function test_SuccessfulStakeClaimAndRedeem() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(1);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);
        // Claim rewards
        stakingContract.claimRewards();

        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);
        rewardToken.approve(address(stakingContract), amount);

        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(1);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        uint256 redeemableAmount = stakingContract.calculateRedeemableAmount(
            user,
            1
        );
        console.logUint(redeemableAmount);

        stakingContract.redeem(1);

        vm.stopPrank();
    }

    // Attempt to redeem with insufficient reward tokens approved
    function test_RedeemWithInsufficientRewardTokensApproved() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);
        stakingContract.claimRewards();

        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        rewardToken.approve(address(stakingContract), amount / 2); // Approving only half the rewards
        vm.expectRevert();
        stakingContract.redeem(1);
    }

    // Attempt to redeem if no time passed
    function test_RedeemIfNoTimePassed() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);
        stakingContract.claimRewards();

        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);

        rewardToken.approve(address(stakingContract), amount);
        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(1);
    }

    // Attempt to redeem with incorrect claim ID
    function testFuzz_RedeemWithIncorrectClaimId(uint64 randomClaimId) public {
        vm.assume(randomClaimId > 1);
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);
        stakingContract.claimRewards();

        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        rewardToken.approve(address(stakingContract), amount);
        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(randomClaimId);
    }

    // Atempt to claim rewards & redeem multiple times
    function test_ClaimAndRedeemMultipleTimes() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);
        stakingContract.claimRewards();

        vm.expectRevert("No rewards");
        stakingContract.claimRewards();

        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        rewardToken.approve(address(stakingContract), amount);
        stakingContract.redeem(1);

        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(1);

        // Check final claim after redemption
        (amount, blockNumber) = stakingContract.claims(user, 1);
        assertEq(amount, 0, "Final claim amount should be 0 after redemption");
        vm.stopPrank();
    }

    // Check after claim & redeem multiple times
    function test_CheckAfterClaimAndRedeemMultipleTimes() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        stakingContract.claimRewards();
        (uint256 amountBefore, uint64 blockNumberBefore) = stakingContract
            .claims(user, 1);

        console.logUint(amountBefore);
        console.logUint(blockNumberBefore);

        vm.roll(block.number + 2000);
        vm.warp(block.timestamp + 2000 * 4);

        stakingContract.claimRewards();
        (uint256 amountAfter, uint64 blockNumberAfter) = stakingContract.claims(
            user,
            2
        );

        console.logUint(amountAfter);
        console.logUint(blockNumberAfter);

        assertEq(
            blockNumberAfter - blockNumberBefore,
            2000,
            "Block Number must increase by 2000"
        );

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        rewardToken.approve(address(stakingContract), amountBefore);
        stakingContract.redeem(1);
        vm.expectRevert();
        stakingContract.redeem(2);

        rewardToken.approve(address(stakingContract), amountAfter);
        stakingContract.redeem(2);

        (amountBefore, ) = stakingContract.claims(user, 1);
        (amountAfter, ) = stakingContract.claims(user, 2);
        assertEq(amountBefore, 0, "Amout must be zero");
        assertEq(amountAfter, 0, "Amout must be zero");
        vm.stopPrank();
    }

    // Fuzz Check the block Number after claim multiple times
    function testFuzz_CheckBlockNumberAfterClaimMultiple(
        uint64 randomBlockCount
    ) public {
        vm.assume(randomBlockCount > 0);
        vm.assume(randomBlockCount < 1e8);
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        vm.roll(block.number + 1000);
        vm.warp(block.timestamp + 1000 * 4);

        stakingContract.claimRewards();
        (uint256 amountBefore, uint64 blockNumberBefore) = stakingContract
            .claims(user, 1);

        console.logUint(amountBefore);
        console.logUint(blockNumberBefore);

        vm.roll(block.number + randomBlockCount);
        vm.warp(block.timestamp + randomBlockCount * 4);

        stakingContract.claimRewards();
        (uint256 amountAfter, uint64 blockNumberAfter) = stakingContract.claims(
            user,
            2
        );

        console.logUint(amountAfter);
        console.logUint(blockNumberAfter);

        assertEq(
            blockNumberAfter - blockNumberBefore,
            randomBlockCount,
            "Block Number must increase by random"
        );
        vm.stopPrank();
    }
}
