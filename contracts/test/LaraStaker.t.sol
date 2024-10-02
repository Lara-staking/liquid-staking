// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@contracts/LaraStaking.sol";
import "@contracts/LaraToken.sol";
import "@contracts/veLara.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LaraStakeV2} from "@contracts/test/utils/LaraStakeV2.sol";

import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract LaraStakingContractTest is Test {
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
        assertEq(rewardToken.balanceOf(address(this)), 100000000 ether, "Deployer should have 100M veLARA");

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
        assertEq(stakingToken.balanceOf(user), 10000000 ether, "User should have 10M LARA");
    }

    function test_simpleDeposit_ConvertsLaraToVeLara() public {
        // vest some LARA to get veLARA
        stakingToken.approve(address(rewardToken), 1000000 ether);
        uint256 veLaraBalanceBefore = rewardToken.balanceOf(address(this));
        rewardToken.deposit(1000000 ether);
        uint256 veLaraBalanceAfter = rewardToken.balanceOf(address(this));

        assertEq(veLaraBalanceAfter - veLaraBalanceBefore, 1000000 ether, "User should have 1M veLARA");
    }

    function simulateSpecificMaturity(uint256 maturityBlockCount) internal {
        vm.startPrank(user);
        stakingToken.approve(address(stakingContract), STAKED_AMOUNT);
        stakingContract.stake(STAKED_AMOUNT);
        vm.stopPrank();

        // Simulate reward accumulation over a year
        uint256 blocksPerYear = SECONDS_PER_YEAR / BLOCK_TIME; // Assuming 4 seconds per block
        vm.roll(block.number + blocksPerYear);
        vm.warp(block.timestamp + SECONDS_PER_YEAR);

        // Calculate expected rewards based on 13% APY
        uint256 yearlyRewards = STAKED_AMOUNT * APY / 100;
        uint256 maturityRatio = maturityBlockCount * 1e18 / MATURITY_BLOCK_COUNT > 1e18
            ? 1e18
            : maturityBlockCount * 1e18 / MATURITY_BLOCK_COUNT;
        uint256 expectedRewards = yearlyRewards * maturityRatio / 1e18;

        // Claim rewards
        vm.prank(user);
        stakingContract.claimRewards();

        // Check claim
        (uint256 amount, uint64 blockNumber) = stakingContract.claims(user, 1);
        assertApproxEqRel(
            amount, yearlyRewards, 0.001e18, "Claim amount should be equal to expected rewards based on ~13% APY"
        );
        assertEq(blockNumber, block.number, "Claim block number should be current block");

        // simulate full maturity
        vm.warp(block.timestamp + maturityBlockCount * BLOCK_TIME);
        vm.roll(block.number + maturityBlockCount);

        uint256 rewardTokenBalanceBefore = rewardToken.balanceOf(address(user));
        uint256 stakingTokenBalanceBefore = stakingToken.balanceOf(address(user));
        // Redeem after maturity
        vm.startPrank(user);
        rewardToken.approve(address(stakingContract), amount);

        uint256 redeemableAmount = stakingContract.calculateRedeemableAmount(user, 1);

        stakingContract.redeem(1);

        uint256 rewardTokenBalanceAfter = rewardToken.balanceOf(address(user));
        uint256 stakingTokenBalanceAfter = stakingToken.balanceOf(address(user));
        assertEq(
            redeemableAmount,
            stakingTokenBalanceAfter - stakingTokenBalanceBefore,
            "Redeemable amount should be equal to claimed amount"
        );
        assertEq(
            rewardTokenBalanceBefore - rewardTokenBalanceAfter,
            amount,
            "Reward token balance should decrease by claimed amount"
        );
        assertApproxEqRel(
            stakingTokenBalanceAfter - stakingTokenBalanceBefore,
            expectedRewards,
            0.001e18,
            "Staking token balance should increase by expected rewards"
        );
        vm.stopPrank();
        // Check final claim
        (amount, blockNumber) = stakingContract.claims(user, 1);
        assertEq(amount, 0, "Final claim amount should be 0 after redemption");
    }

    function test_APYCalculation_6Months_FullMaturity() public {
        simulateSpecificMaturity(MATURITY_BLOCK_COUNT);
    }

    function test_APYCalculation_3Months_HalfMaturity() public {
        simulateSpecificMaturity(MATURITY_BLOCK_COUNT / 2);
    }

    function test_APYCalculation_9Months_OverlyMature() public {
        simulateSpecificMaturity(MATURITY_BLOCK_COUNT * 3 / 2);
    }

    function testFuzz_APYCalculation_RandomMaturity(uint256 randomMaturity) public {
        vm.assume(randomMaturity > 0);
        vm.assume(randomMaturity < MATURITY_BLOCK_COUNT * 1000);
        simulateSpecificMaturity(randomMaturity);
    }

    function test_Upgrade() public {
        address implContract = Upgrades.getImplementationAddress(address(stakingContract));
        assertNotEq(implContract, address(0), "Implementation contract should be set");

        // upgrade proxy to LaraStakeV2
        Upgrades.upgradeProxy(
            address(stakingContract), "LaraStakeV2.sol", abi.encodeCall(LaraStakeV2.setRandomSlot, (21))
        );
        address newImplContract = Upgrades.getImplementationAddress(address(stakingContract));
        LaraStakeV2 laraStakeV2 = LaraStakeV2(payable(address(stakingContract)));
        assertEq(laraStakeV2.getRandomSlot(), 21, "Random slot should be 21");
        assertNotEq(implContract, newImplContract, "Implementation contract should be different");
    }
}
