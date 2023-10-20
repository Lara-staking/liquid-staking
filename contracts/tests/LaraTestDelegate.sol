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

contract LaraTest is Test {
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
        mockDpos = new MockDpos{value: 1000000 ether}(validators);

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

    function testGetNodesForDelegation() public {
        // define value
        uint256 amount = 500000 ether;

        // call the function
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // check the length of the array
        assertEq(tentativeDelegations.length, 1, "Wrong length of array");

        // check if the value is the right one. It should be 500000 ether for the first validator
        assertEq(tentativeDelegations[0].amount, amount, "Wrong value");
    }

    function testFailStakeAmountTooLow() public {
        // Call the function with an amount less than the minimum stake amount
        vm.expectRevert(StakeAmountTooLow.selector);
        lara.stake{value: 500 ether}(500 ether);
    }

    function testFailStakeValueTooLow() public {
        // Call the function with a value less than the staking amount
        vm.expectRevert(StakeValueTooLow.selector);
        lara.stake{value: 400000 ether}(500000 ether);
    }

    uint256 firstAmountToStake = 500000 ether;

    function testStakeToSingleValidator() public {
        uint256 amount = firstAmountToStake;

        // Call the function
        uint256 remainingAmount = lara.stake{value: amount}(amount);

        // Check the remaining amount
        assertEq(remainingAmount, 0);

        // Check the delegated amount
        assertEq(lara.getStakedAmount(address(this)), amount);

        // Check the individual delegations
        Lara.IndividualDelegation[] memory delegations = lara
            .getIndividualDelegations(address(this));
        assertEq(delegations.length, 1);
        for (uint256 i = 0; i < delegations.length; i++) {
            assertEq(delegations[i].amount, amount);

            //check validatorDelegations
            Lara.ValidatorDelegation[] memory validatorDelegations = lara
                .getValidatorDelegations(delegations[i].validator);
            assertEq(validatorDelegations.length, 1);
            assertEq(validatorDelegations[0].amount, amount);

            //check protocolTotalStakeAtValdiator
            assertEq(
                lara.getProtocolTotalStakeAtValdiator(delegations[i].validator),
                amount
            );
        }

        // check the user's stTARA balance
        assertEq(stTaraToken.balanceOf(address(this)), amount);
    }

    function testStakeToMultipleValidators() public {
        uint256 amount = 100000000 ether;

        // get the stake distribution first to check
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // Call the function with different address
        address staker1 = address(333);
        vm.prank(staker1);
        vm.deal(staker1, amount + 1 ether);
        uint256 remainingAmount = lara.stake{value: amount}(amount);

        // Check the remaining amount
        assertEq(remainingAmount, 0);

        // Check the delegated amount
        assertEq(lara.getStakedAmount(staker1), amount);

        // Check the individual delegations
        Lara.IndividualDelegation[] memory delegations = lara
            .getIndividualDelegations(staker1);
        assertEq(delegations.length, 2, "Wrong length of array");
        for (uint256 i = 0; i < delegations.length; i++) {
            for (uint256 j = 0; j < tentativeDelegations.length; j++) {
                if (
                    tentativeDelegations[j].validator ==
                    delegations[i].validator
                ) {
                    assertEq(
                        tentativeDelegations[j].amount,
                        delegations[i].amount,
                        "Wrong value"
                    );
                }
            }
        }
    }

    function testFailValidatorsFull() public {
        uint256 amount = 100000000 ether;

        // Call the function with different address
        address staker2 = address(444);
        vm.prank(staker2);
        vm.deal(staker2, amount + 1 ether);
        vm.expectRevert("No amount could be staked. Validators are full.");
        lara.stake{value: amount}(amount);
    }

    // Fuzz test for staking
    function testFuzz_stake(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 430000000 ether);

        // Call the function
        uint256 remainingAmount = lara.stake{value: amount}(amount);

        // Check the remaining amount
        assertEq(remainingAmount, 0);

        // Check the delegated amount
        assertEq(lara.getStakedAmount(address(this)), amount);
    }

    // Fuzz test for delegation
    function testFuzz_delegation(uint256 amount) public {
        vm.assume(amount > 1000 ether);
        vm.assume(amount < 430000000 ether);

        // get the stake distribution first to check
        IApyOracle.TentativeDelegation[]
            memory tentativeDelegations = mockApyOracle.getNodesForDelegation(
                amount
            );

        // Call the function with different address
        address staker1 = address(333);
        vm.prank(staker1);
        vm.deal(staker1, amount + 1 ether);
        uint256 remainingAmount = lara.stake{value: amount}(amount);

        // Check the remaining amount
        assertEq(remainingAmount, 0);

        // Check the delegated amount
        assertEq(lara.getStakedAmount(staker1), amount);
    }
}
