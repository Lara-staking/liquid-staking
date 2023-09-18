// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IApyOracle {
    struct NodeData {
        address account;
        uint16 rank;
        uint16 apy;
        uint64 fromBlock;
        uint64 toBlock;
        uint256 pbftCount;
    }

    event NodeDataUpdated(address indexed node, uint16 apy, uint256 pbftCount);

    function getNodeCount() external view returns (uint256);

    function getNodesList() external view returns (address[] memory);

    function updateNodeCount(uint256 count) external;

    function getNodeData(address node) external view returns (NodeData memory);

    function updateNodeData(address node, NodeData memory data) external;

    function getDataFeedAddress() external view returns (address);
}
