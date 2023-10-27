// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol rework with call instead of delegatecall)
pragma solidity 0.8.17;

import "./interfaces/IApyOracle.sol";
import "./interfaces/IDPOS.sol";

contract ApyOracle is IApyOracle {
    constructor(address dataFeed, address dpos) {
        _dataFeed = dataFeed;
        _dpos = DposInterface(dpos);
    }

    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    address private immutable _dataFeed;
    DposInterface private immutable _dpos;
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

    /**
     * Returns the list of nodes that can be delegated to, along with the amount that can be delegated to each node.
     * @param amount The amount to be delegated
     */
    function getNodesForDelegation(
        uint256 amount
    ) external view returns (TentativeDelegation[] memory) {
        // we loop through the nodesList and see check if the node's able to capture thw whole amount
        // if not, we take the next node and so on. We return the TentativeDelegation's until the amount is
        // fully captured
        TentativeDelegation[]
            memory tentativeDelegations = new TentativeDelegation[](nodeCount);
        uint256 tentativeDelegationsCount = 0;
        uint256 totalAmount = amount;
        for (uint256 i = 0; i < nodeCount; i++) {
            address node = nodesList[i];
            uint256 totalStake = _dpos.getValidator(node).total_stake;
            uint256 availableDelegation = maxValidatorStakeCapacity -
                totalStake;
            if (totalAmount == 0) {
                break;
            }
            if (availableDelegation > 0) {
                uint256 stakeSlot = 0;
                if (availableDelegation < totalAmount) {
                    stakeSlot = availableDelegation;
                } else {
                    stakeSlot = totalAmount;
                }
                totalAmount -= stakeSlot;
                tentativeDelegations[
                    tentativeDelegationsCount
                ] = TentativeDelegation(node, stakeSlot);
                tentativeDelegationsCount++;
            }
        }
        // Create a new array with the exact length
        TentativeDelegation[] memory result = new TentativeDelegation[](
            tentativeDelegationsCount
        );
        for (uint256 i = 0; i < tentativeDelegationsCount; i++) {
            result[i] = tentativeDelegations[i];
        }
        return result;
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
        emit NodeDataUpdated(node, data.apy, data.rating);
    }
}
