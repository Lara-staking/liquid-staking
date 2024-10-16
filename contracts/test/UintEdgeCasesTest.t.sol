// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@contracts/LaraStaking.sol";
import "@contracts/veLara.sol";
import "@contracts/LaraToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract UintEdgeCasesTest is Test {
    LaraStaking public stakingContract;
    veLara public rewardToken;
    LaraToken public stakingToken;
    address user = address(0x123);
    address treasury = address(0x789);

    uint256 public MAX_UINT256 = type(uint256).max;
    uint256 public MIN_UINT256 = 0;

    uint64 public MAX_UINT64 = type(uint64).max;
    uint256 STAKED_AMOUNT = 100 ether;

    uint256 BLOCK_TIME = 4; //seconds
    uint256 SECONDS_PER_YEAR = 365 * 24 * 60 * 60;

    uint256 MATURITY_BLOCK_COUNT = 426445; // 6 months

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

        // Add 1M LARA to the staking contract
        rewardToken.approve(address(stakingContract), 1_000_000 ether);
        stakingContract.depositRewardTokens(1_000_000 ether);

        // Send 10M LARA to user
        stakingToken.transfer(user, 10_000_000 ether);
        assertEq(
            stakingToken.balanceOf(user),
            10_000_000 ether,
            "User should have 10M LARA"
        );
    }

    function test_ZeroStakingAmount() public {
        vm.startPrank(user);

        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);

        // try to stake 0 tokens
        vm.expectRevert("Staking 0 tokens");
        stakingContract.stake(0);

        vm.stopPrank();
    }

    function test_ZeroWithdrawalAmount() public {
        vm.startPrank(user);

        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        // try to withdraw 0 tokens
        vm.expectRevert("Withdrawing 0 tokens");
        stakingContract.withdraw(0);

        vm.stopPrank();
    }

    function test_MaxUintWithdrawal() public {
        vm.startPrank(user);

        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        // try to withdraw more than staked amount (overflow scenario)
        vm.expectRevert("Withdrawing more than staked");
        stakingContract.withdraw(MAX_UINT256);

        vm.stopPrank();
    }

    function test_ClaimRewardsFailsIfTimeNotElapsed() public {
        vm.startPrank(user);
        uint256 stakingAmount = 10_000 ether;
        stakingToken.approve(address(stakingContract), stakingAmount);
        stakingContract.stake(stakingAmount);

        vm.expectRevert("No rewards");
        stakingContract.claimRewards();
    }

    function test_ExcessiveClaimId() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);

        uint256 currentTimestamp = vm.getBlockTimestamp();
        vm.warp(block.timestamp + 30 days);

        stakingContract.claimRewards();

        // try to redeem rewards for an invalid claimId
        vm.expectRevert("No rewards to redeem or already redeemed");
        stakingContract.redeem(MAX_UINT64);

        vm.stopPrank();
    }

    function test_ExcessiveMaturitySimulation() public {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // simulate maturity with excessive block number change
        vm.roll(MAX_UINT256);

        // check claim rewards after overflow-like block increment
        vm.startPrank(user);
        vm.expectRevert("No rewards");
        stakingContract.claimRewards();

        vm.stopPrank();
    }

    function testSuccessfulClaimRewards() public {
        vm.startPrank(user);
        uint256 stakingAmount = 10_000 ether;
        stakingToken.approve(address(stakingContract), stakingAmount);
        stakingContract.stake(stakingAmount);

        vm.warp(block.timestamp + 30 days);
        stakingContract.claimRewards();

        uint64 claimId = stakingContract.CURRENT_CLAIM_ID() - 1;
        (, uint64 blockNumber) = stakingContract.claims(user, claimId);

        assertEq(
            blockNumber,
            block.number,
            "Claim block number should be correct"
        );
    }
}
