// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol rework with call instead of delegatecall)
pragma solidity 0.8.17;

import "./interfaces/INodeContinuityOracle.sol";

contract NodeContinuityOracle is INodeContinuityOracle {
    constructor(address dataFeed) {
        _dataFeed = dataFeed;
    }

    address private immutable _dataFeed;
    mapping(address => uint64[]) public nodeStatsUpdateTimestamps;
    mapping(uint64 => INodeContinuityOracle.NodeStats) public nodeStats;

    modifier OnlyDataFeed() {
        require(
            msg.sender == _dataFeed,
            "ApyOracle: caller is not the data feed"
        );
        _;
    }

    function getDataFeedAddress() external view returns (address) {
        return _dataFeed;
    }

    function updateNodeStats(
        address node,
        uint64 timestamp,
        NodeStats memory data
    ) external override OnlyDataFeed {
        require(
            nodeStats[timestamp].lastDagTimestamp == 0 ||
                nodeStats[timestamp].lastDagTimestamp == 0,
            "INodeContinuityOracle: timestamp already exists"
        );
        nodeStats[timestamp] = data;
        nodeStatsUpdateTimestamps[node].push(timestamp);
        emit NodeDataUpdated(node, timestamp, data.pbftCount);
    }

    function getNodeUpdateTimestamps(
        address node
    ) external view override returns (uint64[] memory timestamps) {
        return nodeStatsUpdateTimestamps[node];
    }

    function getNodeStatsFrom(
        uint64 timestamp
    ) external view override returns (NodeStats memory) {
        return nodeStats[timestamp];
    }
}
