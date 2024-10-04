// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@contracts/LaraStaking.sol";
import "@contracts/veLara.sol";
import "@contracts/LaraToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract OverflowUnderflowLoopTests is Test {
    LaraStaking public stakingContract;
    veLara public rewardToken;
    LaraToken public stakingToken;
    address user = address(0x123);
    address treasury = address(0x789);

    uint256 public MAX_UINT256 = type(uint256).max;
    uint256 public MIN_UINT256 = 0;

    uint64 public MAX_UINT64 = type(uint64).max;

    uint256 STAKED_AMOUNT = 100 ether;
    uint256 BLOCKS_TO_ADVANCE = 100;

    function setUp() public {
        stakingToken = new LaraToken(treasury);
        rewardToken = new veLara(address(stakingToken));

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
                    426445
                )
            )
        );

        stakingContract = LaraStaking(payable(stakingContractProxy));

        // add 1M LARA to the staking contract
        rewardToken.approve(address(stakingContract), 1_000_000 ether);
        stakingContract.depositRewardTokens(1_000_000 ether);

        // send 10M LARA to user
        stakingToken.transfer(user, 10_000_000 ether);
        assertEq(
            stakingToken.balanceOf(user),
            10_000_000 ether,
            "User should have 10M LARA"
        );
    }

    function test_LoopOverflow_MaxUintCondition() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // simulate extreme maturity blocks to test loop handling in reward calculations
        uint256 largeBlockAdvance = 1e18;
        vm.roll(block.number + largeBlockAdvance);
        vm.warp(block.timestamp + largeBlockAdvance * 4);

        vm.startPrank(user);
        vm.expectRevert(); // expect a revert due to overflow conditions in the loop
        stakingContract.claimRewards();
        vm.stopPrank();
    }

    function test_LoopUnderflow_MinUintCondition() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // simulate going backward to 0 blocks
        vm.roll(MIN_UINT256);

        vm.startPrank(user);
        vm.expectRevert(); // expect a revert due to underflow conditions in the loop
        stakingContract.claimRewards();
        vm.stopPrank();
    }

    function test_LoopHandling_WithHighIterationCount() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // set a high iteration count to test for overflow in loops
        vm.roll(block.number + 1e8);
        vm.warp(block.timestamp + (1e8 * 4));

        vm.startPrank(user);
        stakingContract.claimRewards();
        vm.stopPrank();

        // assert the claim was successful without overflow issues
        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);
        assertGt(amount, 0, "Rewards should have been calculated properly");
        assertEq(
            blockNumber,
            block.number,
            "Claim block number should be the current block"
        );
    }

    function testFuzz_LoopHandling_RandomIterations(
        uint256 randomBlockAdvance
    ) public {
        vm.assume(randomBlockAdvance > 0);
        vm.assume(randomBlockAdvance < 1e6);

        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // advance by a random number of blocks to simulate loop iteration
        vm.roll(block.number + randomBlockAdvance);
        vm.warp(block.timestamp + randomBlockAdvance * 4);

        vm.startPrank(user);
        stakingContract.claimRewards();
        vm.stopPrank();

        // assert that the claim was successful and no overflow occurred
        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);
        assertGt(amount, 0, "Rewards should have been calculated properly");
        assertEq(
            blockNumber,
            block.number,
            "Claim block number should be the current block"
        );
    }
}
