// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol rework with call instead of delegatecall)
pragma solidity 0.8.17;

import "./interfaces/IApyOracle.sol";

contract ApyOracle is IApyOracle {
    constructor(address dataFeed) {
        _dataFeed = dataFeed;
    }

    address private immutable _dataFeed;
    uint256 public nodeCount;
    address[] public nodesList;
    mapping(address => IApyOracle.NodeData) public nodes;

    modifier OnlyDataFeed() {
        require(
            msg.sender == _dataFeed,
            "ApyOracle: caller is not the data feed"
        );
        _;
    }

    function getNodeCount() external view override returns (uint256) {
        return nodeCount;
    }

    function getNodesList() external view override returns (address[] memory) {
        return nodesList;
    }

    function updateNodeCount(uint256 count) external override OnlyDataFeed {
        nodeCount = count;
    }

    function getDataFeedAddress() external view returns (address) {
        return _dataFeed;
    }

    function getNodeData(
        address node
    ) external view override returns (IApyOracle.NodeData memory) {
        return nodes[node];
    }

    function updateNodeData(
        address node,
        NodeData memory data
    ) external override OnlyDataFeed {
        require(
            nodes[node].fromBlock < data.fromBlock,
            "ApyOracle: fromBlock must be greater than the previous one"
        );
        require(
            data.fromBlock < data.toBlock,
            "ApyOracle: fromBlock must be less than toBlock"
        );
        if (nodes[node].account == address(0)) {
            nodeCount++;
            nodesList.push(node);
        }
        nodes[node] = data;
        emit NodeDataUpdated(node, data.apy, data.pbftCount);
    }
}
