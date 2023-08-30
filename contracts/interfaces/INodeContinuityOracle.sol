// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INodeContinuityOracle {
    struct NodeStats {
        uint64 dagsCount;
        uint64 lastDagTimestamp;
        uint64 lastPbftTimestamp;
        uint64 lastTransactionTimestamp;
        uint64 pbftCount;
        uint64 transactionsCount;
    }

    event NodeDataUpdated(
        address indexed node,
        uint64 timestamp,
        uint256 pbftCount
    );

    function getNodeUpdateTimestamps(
        address node
    ) external view returns (uint64[] memory timestamps);

    function getNodeStatsFrom(
        uint64 timestamp
    ) external view returns (NodeStats memory);

    function updateNodeStats(
        address node,
        uint64 timestamp,
        NodeStats memory stats
    ) external;

    function getDataFeedAddress() external view returns (address);
}
