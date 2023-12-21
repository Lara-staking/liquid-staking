// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

/**
 * @title IApyOracle
 * @dev This interface defines the methods for APY Oracle
 */
interface IApyOracle {
    /**
     * @dev Struct to store node data
     */
    struct NodeData {
        uint256 rating;
        address account;
        uint64 fromBlock;
        uint64 toBlock;
        uint16 rank;
        uint16 apy;
    }

    /**
     * @dev Struct to store tentative delegation data
     */
    struct TentativeDelegation {
        address validator;
        uint256 amount;
        uint256 rating;
    }

    /**
     * @dev Struct to store tentative redelegation data
     */
    struct TentativeReDelegation {
        address from;
        address to;
        uint256 amount;
        uint256 toRating;
    }

    /**
     * @dev Event to be emitted when node data is updated
     */
    event NodeDataUpdated(address indexed node, uint16 apy, uint256 pbftCount);

    /**
     * @dev Function to get the node count
     */
    function getNodeCount() external view returns (uint256);

    /**
     * @dev Function to get nodes for delegation
     */
    function getNodesForDelegation(
        uint256 amount
    ) external returns (TentativeDelegation[] memory);

    /**
     * @dev Function to get rebalance list
     */
    function getRebalanceList(
        TentativeDelegation[] memory currentValidators
    ) external returns (TentativeReDelegation[] memory);

    /**
     * @dev Function to update the node count
     */
    function updateNodeCount(uint256 count) external;

    /**
     * @dev Function to batch update node data
     */
    function batchUpdateNodeData(IApyOracle.NodeData[] memory data) external;

    /**
     * @dev Function to get node data
     */
    function getNodeData(address node) external view returns (NodeData memory);

    /**
     * @dev Function to update node data
     */
    function updateNodeData(address node, NodeData memory data) external;

    /**
     * @dev Function to get data feed address
     */
    function getDataFeedAddress() external view returns (address);
}
