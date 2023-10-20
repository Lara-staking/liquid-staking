// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IApyOracle {
    struct NodeData {
        address account;
        uint16 rank;
        uint256 rating;
        uint16 apy;
        uint64 fromBlock;
        uint64 toBlock;
    }

    struct TentativeDelegation {
        address validator;
        uint256 amount;
    }

    event NodeDataUpdated(address indexed node, uint16 apy, uint256 pbftCount);

    function getNodeCount() external view returns (uint256);

    function getNodesForDelegation(
        uint256 amount
    ) external view returns (TentativeDelegation[] memory);

    function updateNodeCount(uint256 count) external;

    function getNodeData(address node) external view returns (NodeData memory);

    function updateNodeData(address node, NodeData memory data) external;

    function getDataFeedAddress() external view returns (address);
}
