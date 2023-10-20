// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/LaraErrors.sol";

contract LaraTestRewards is Test {
    Lara lara;
    ApyOracle mockApyOracle;
    MockDpos mockDpos;
    StTARA stTaraToken;

    function setUp() public {
        for (uint16 i = 0; i < validators.length; i++) {
            validators[i] = vm.addr(i + 1);
        }
        setupValidators();
        setupApyOracle();
        setupLara();
    }

    uint16 numValidators = 12;

    address[] validators = new address[](numValidators);

    function setupValidators() private {
        // create a random array of addresses as internal validators

        // Set up the apy oracle with a random data feed address and a mock dpos contract
        vm.deal(address(mockDpos), 1000000 ether);
        mockDpos = new MockDpos{value: 12000000 ether}(validators);

        // check if MockDPos was initialized successfully
        assertEq(
            mockDpos.isValidatorRegistered(validators[0]),
            true,
            "MockDpos was not initialized successfully"
        );
        assertEq(
            mockDpos.isValidatorRegistered(validators[1]),
            true,
            "MockDpos was not initialized successfully"
        );
    }

    function setupApyOracle() private {
        mockApyOracle = new ApyOracle(address(this), address(mockDpos));

        // setting up the two validators in the mockApyOracle
        for (uint16 i = 0; i < validators.length; i++) {
            mockApyOracle.updateNodeData(
                validators[i],
                IApyOracle.NodeData({
                    account: validators[i],
                    rank: i,
                    apy: i * 1000,
                    fromBlock: 1,
                    toBlock: 15000,
                    rating: 813 //meaning 8.13
                })
            );
        }

        // check if the node data was set successfully
        assertEq(
            mockApyOracle.getNodeCount(),
            numValidators,
            "Node data was not set successfully"
        );
    }

    function setupLara() private {
        stTaraToken = new StTARA();
        lara = new Lara(
            address(stTaraToken),
            address(mockDpos),
            address(mockApyOracle)
        );
        stTaraToken.setLaraAddress(address(lara));
    }

    function testClaimRewards() public {
        // Call the function with prefedined address
        address staker1 = address(333);
        vm.deal(staker1, 10000 ether);
        vm.prank(staker1);
        // Delegate some stake to the validator just for simulation
        uint256 delegationTimestamp = block.timestamp;
        lara.stake{value: 10000 ether}(10000 ether);

        vm.warp(block.timestamp + 100000);
        vm.prank(staker1);
        // Claim the rewards
        uint256 protocolTotalStakeAtValidator = lara
            .getProtocolTotalStakeAtValdiator(validators[0]);
        uint256 firstDelegationToValidator = lara.getFirstDelegationToValidator(
            validators[0]
        );

        uint256 balanceBefore = address(staker1).balance;
        lara.claimRewards(staker1);

        uint256 rewards = (((10000 ether * 1000 ether) /
            protocolTotalStakeAtValidator) *
            (block.timestamp - delegationTimestamp)) /
            (block.timestamp - firstDelegationToValidator);

        // Check that the rewards have been claimed
        assertApproxEqRel(
            address(staker1).balance - balanceBefore,
            rewards,
            100000 gwei,
            "Delegator balance is incorrect"
        );
    }

    function testClaimRewardsWithNoDelegation() public {
        // Set up a delegator with no delegation
        address delegator = vm.addr(13); // an address not in the validators array

        // Claim the rewards
        vm.prank(delegator);
        vm.deal(delegator, 10000 ether);
        lara.claimRewards(delegator);

        // Check that no rewards have been claimed
        ILara.Reward[] memory delegatorRewards = lara.getRewards(delegator);
        assertEq(
            delegatorRewards.length,
            0,
            "Rewards were claimed incorrectly"
        );
        assertEq(
            address(delegator).balance,
            10000 ether,
            "Delegator balance is incorrect"
        );
    }

    function testProportionalRewards() public {
        // Set the block timestamp to a specific value
        address delegator1 = vm.addr(137);
        address delegator2 = vm.addr(138);
        address delegator3 = vm.addr(139);

        vm.prank(delegator1);
        vm.deal(delegator1, 1000 ether);
        // Stake 1000 tokens from delegator1
        lara.stake{value: 1000 ether}(1000 ether);

        uint64 timeAddition = 10000;
        // Set the block timestamp to a different value
        vm.prank(delegator2);
        vm.deal(delegator2, 2000 ether);
        // Stake 2000 tokens from delegator2
        lara.stake{value: 2000 ether}(2000 ether);

        // Set the block timestamp to a different value
        vm.deal(delegator3, 3000 ether);
        vm.prank(delegator3);
        // Stake 3000 tokens from delegator3
        lara.stake{value: 3000 ether}(3000 ether);

        vm.warp(block.timestamp + timeAddition);
        // Claim rewards for delegator1
        vm.prank(delegator1);
        lara.accrueRewardsForDelegator(delegator1);

        uint256 expectedRewardForDelegator1 = 166666666666666666666;
        uint256 expectedRewardForDelegator2 = 333333333333333333333;
        uint256 expectedRewardForDelegator3 = 500000000000000000000;
        uint256[] memory expectedRewards = new uint256[](3);
        address[] memory delegators = new address[](3);
        delegators[0] = delegator1;
        delegators[1] = delegator2;
        delegators[2] = delegator3;
        expectedRewards[0] = expectedRewardForDelegator1;
        expectedRewards[1] = expectedRewardForDelegator2;
        expectedRewards[2] = expectedRewardForDelegator3;

        // check the rewards for all validators
        for (uint256 i = 0; i < expectedRewards.length; i++) {
            ILara.Reward[] memory delegator1Rewards = lara.getRewards(
                delegators[i]
            );
            assertEq(delegator1Rewards.length, 1, "Rewards were not accrued");
            assertApproxEqRel(
                delegator1Rewards[0].amount,
                expectedRewards[i],
                100000 gwei,
                "Rewards were not accrued correctly on first accruement"
            );
        }

        vm.warp(block.timestamp + timeAddition);
        // Claim rewards for delegator2
        vm.prank(delegator2);
        lara.accrueRewardsForDelegator(delegator2);

        // check the rewards for all validators
        for (uint256 i = 0; i < expectedRewards.length; i++) {
            ILara.Reward[] memory delegator1Rewards = lara.getRewards(
                delegators[i]
            );
            assertEq(delegator1Rewards.length, 2, "Rewards were not accrued");
            uint256 totalRewards = 0;
            for (uint256 j = 0; j < delegator1Rewards.length; j++) {
                totalRewards += delegator1Rewards[j].amount;
            }
            assertApproxEqRel(
                totalRewards,
                expectedRewards[i] * 2, // we doubled the time period once
                100000 gwei,
                "Rewards were not accrued correctly on second accruement"
            );
        }

        vm.warp(block.timestamp + timeAddition);
        // Claim rewards for delegator3
        vm.prank(delegator3);
        lara.accrueRewardsForDelegator(delegator3);

        // check the rewards for all validators
        for (uint256 i = 0; i < expectedRewards.length; i++) {
            ILara.Reward[] memory delegator1Rewards = lara.getRewards(
                delegators[i]
            );
            assertEq(delegator1Rewards.length, 3, "Rewards were not accrued");
            uint256 totalRewards = 0;
            for (uint256 j = 0; j < delegator1Rewards.length; j++) {
                totalRewards += delegator1Rewards[j].amount;
            }
            assertApproxEqRel(
                totalRewards,
                expectedRewards[i] * 3, // we tripled the initial time period
                100000 gwei,
                "Rewards were not accrued correctly on third accruement"
            );
        }
    }

    function testClaimProportionalRewards() public {
        address delegator1 = vm.addr(137);
        address delegator2 = vm.addr(138);
        address delegator3 = vm.addr(139);

        uint256 expectedRewardForDelegator1 = 166666666666666666666;
        uint256 expectedRewardForDelegator2 = 333333333333333333333;
        uint256 expectedRewardForDelegator3 = 500000000000000000000;
        uint256[] memory expectedRewards = new uint256[](3);
        address[] memory delegators = new address[](3);
        delegators[0] = delegator1;
        delegators[1] = delegator2;
        delegators[2] = delegator3;
        expectedRewards[0] = expectedRewardForDelegator1;
        expectedRewards[1] = expectedRewardForDelegator2;
        expectedRewards[2] = expectedRewardForDelegator3;

        vm.prank(delegator1);
        vm.deal(delegator1, 1000 ether);
        // Stake 1000 tokens from delegator1
        lara.stake{value: 1000 ether}(1000 ether);

        uint64 timeAddition = 10000;
        // Set the block timestamp to a different value
        vm.prank(delegator2);
        vm.deal(delegator2, 2000 ether);
        // Stake 2000 tokens from delegator2
        lara.stake{value: 2000 ether}(2000 ether);

        // Set the block timestamp to a different value
        vm.deal(delegator3, 3000 ether);
        vm.prank(delegator3);
        // Stake 3000 tokens from delegator3
        lara.stake{value: 3000 ether}(3000 ether);

        vm.warp(block.timestamp + timeAddition);
        // Claim rewards for delegator1
        vm.prank(delegator1);
        // Claim the rewards for once to be calculated for all
        uint256 balanaceBfore = address(delegators[0]).balance;
        lara.claimRewards(delegators[0]);
        uint256 balanaceAfter = address(delegators[0]).balance;
        assertApproxEqRel(
            balanaceAfter - balanaceBfore,
            (expectedRewards[0]),
            100000 gwei,
            "Rewards were not claimed correctly"
        );

        uint256 balanaceBfore1 = address(delegators[1]).balance;
        lara.claimRewards(delegators[1]);
        uint256 balanaceAfter1 = address(delegators[1]).balance;
        assertApproxEqRel(
            balanaceAfter1 - balanaceBfore1,
            (expectedRewards[1] * 2),
            100000 gwei,
            "Rewards were not claimed correctly"
        );

        uint256 balanaceBfore2 = address(delegators[2]).balance;
        lara.claimRewards(delegators[2]);
        uint256 balanaceAfter2 = address(delegators[2]).balance;
        assertApproxEqRel(
            balanaceAfter2 - balanaceBfore2,
            (expectedRewards[2] * 3),
            100000 gwei,
            "Rewards were not claimed correctly"
        );
    }
}
