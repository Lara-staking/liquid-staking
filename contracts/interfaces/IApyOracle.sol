// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IApyOracle {
    struct NodeData {
        uint256 rating;
        address account;
        uint64 fromBlock;
        uint64 toBlock;
        uint16 rank;
        uint16 apy;
    }

    struct TentativeDelegation {
        address validator;
        uint256 amount;
        uint256 rating;
    }

    struct TentativeReDelegation {
        address from;
        address to;
        uint256 amount;
        uint256 toRating;
    }

    event NodeDataUpdated(address indexed node, uint16 apy, uint256 pbftCount);

    function getNodeCount() external view returns (uint256);

    function getNodesForDelegation(
        uint256 amount
    ) external returns (TentativeDelegation[] memory);

    function getRebalanceList(
        TentativeDelegation[] memory currentValidators
    ) external returns (TentativeReDelegation[] memory);

    function updateNodeCount(uint256 count) external;

    function batchUpdateNodeData(IApyOracle.NodeData[] memory data) external;

    function getNodeData(address node) external view returns (NodeData memory);

    function updateNodeData(address node, NodeData memory data) external;

    function getDataFeedAddress() external view returns (address);
}
