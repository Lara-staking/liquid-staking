// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IApyOracle, ApyOracle} from "@contracts/ApyOracle.sol";
import {MockDpos} from "@contracts/mocks/MockDpos.sol";
import {TestSetup} from "@contracts/test/SetUp.t.sol";
import {NotDataFeed} from "@contracts/libs/SharedErrors.sol";

contract ApyOracleTest is TestSetup {
    address public dataFeedAddress = address(this);
    address public secondSignerAddress = address(0x2);

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
    }

    function test_DeployApyOracleAndSetDataFeedAddress() public {
        address datafeedAddress = mockApyOracle.getDataFeedAddress();
        assertEq(dataFeedAddress, datafeedAddress);
    }

    function test_UpdateAndRetrieveNodeData() public {
        address nodeAddress = address(0x3);

        ApyOracle.NodeData memory updatedNodeData =
            IApyOracle.NodeData({rank: 1, account: address(0x4), apy: 500, fromBlock: 1000, toBlock: 2000, rating: 997});

        vm.prank(dataFeedAddress);
        mockApyOracle.updateNodeData(nodeAddress, updatedNodeData);

        ApyOracle.NodeData memory retrievedNodeData = mockApyOracle.getNodeData(nodeAddress);
        assertEq(retrievedNodeData.rank, updatedNodeData.rank);
        assertEq(retrievedNodeData.rating, updatedNodeData.rating);
        assertEq(retrievedNodeData.apy, updatedNodeData.apy);
    }

    function test_UnauthorizedUpdateShouldRevert() public {
        address nodeAddress = address(0x5);
        ApyOracle.NodeData memory updatedNodeData =
            IApyOracle.NodeData({rank: 1, account: address(0x6), apy: 500, fromBlock: 1000, toBlock: 2000, rating: 997});

        vm.prank(secondSignerAddress);
        vm.expectRevert(NotDataFeed.selector);
        mockApyOracle.updateNodeData(nodeAddress, updatedNodeData);
    }
}
