// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol rework with call instead of delegatecall)
pragma solidity ^0.8.20;

import "./interfaces/IApyOracle.sol";
import "./interfaces/IDPOS.sol";

contract ApyOracle is IApyOracle {
    constructor(address dataFeed, address dpos) {
        _dataFeed = dataFeed;
        _dpos = DposInterface(dpos);
    }

    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    uint256 public nodeCount;

    address public immutable _dataFeed;

    address public lara;

    DposInterface public immutable _dpos;

    address[] public nodesList;

    mapping(address => IApyOracle.NodeData) public nodes;

    modifier OnlyDataFeed() {
        require(
            msg.sender == _dataFeed,
            "ApyOracle: caller is not the data feed"
        );
        _;
    }

    modifier OnlyLara() {
        require(msg.sender == lara, "ApyOracle: caller is not Lara");
        _;
    }

    function setLara(address _lara) external OnlyDataFeed {
        lara = _lara;
    }

    function getNodeCount() external view override returns (uint256) {
        return nodeCount;
    }

    function getRebalanceList(
        TentativeDelegation[] memory currentValidators
    ) external override OnlyLara returns (TentativeReDelegation[] memory) {
        if (currentValidators.length == 0 || nodeCount == 0) {
            return new TentativeReDelegation[](0);
        }
        // order the currentValidators by rating
        TentativeDelegation[]
            memory orderedValidators = sortTentativeDelegationsByRating(
                currentValidators
            );

        TentativeReDelegation[]
            memory tentativeReDelegations = new TentativeReDelegation[](
                nodeCount
            );
        uint256 count = 0;
        for (uint256 i = 0; i < nodeCount; i++) {
            address node = nodesList[i];
            if (orderedValidators.length == nodeCount) {
                return new TentativeReDelegation[](0);
            }
            if (orderedValidators.length == i) {
                break;
            }
            if (orderedValidators[i].validator == node) {
                continue;
            }
            if (nodes[nodesList[i]].rating <= orderedValidators[i].rating) {
                continue;
            }
            try _dpos.getValidator(node) returns (
                DposInterface.ValidatorBasicInfo memory validator
            ) {
                uint256 totalStake = validator.total_stake;
                uint256 totalAmount = orderedValidators[i].amount;
                if (totalStake >= maxValidatorStakeCapacity) {
                    continue;
                }
                if (totalAmount == 0) {
                    continue;
                }
                uint256 availableDelegation = maxValidatorStakeCapacity -
                    totalStake;
                if (availableDelegation > 0) {
                    uint256 stakeSlot = 0;
                    if (availableDelegation < totalAmount) {
                        stakeSlot = availableDelegation;
                    } else {
                        stakeSlot = totalAmount;
                    }
                    totalAmount -= stakeSlot;
                    tentativeReDelegations[i] = TentativeReDelegation(
                        orderedValidators[i].validator,
                        node,
                        stakeSlot,
                        nodes[node].rating
                    );
                    count++;
                }
            } catch Error(string memory reason) {
                revert(reason);
            }
        }
        // Create a new array with the exact length
        TentativeReDelegation[] memory result = new TentativeReDelegation[](
            count
        );
        for (uint256 i = 0; i < count; i++) {
            result[i] = tentativeReDelegations[i];
        }
        return result;
    }

    /**
     * Returns the list of nodes that can be delegated to, along with the amount that can be delegated to each node.
     * @param amount The amount to be delegated
     */
    function getNodesForDelegation(
        uint256 amount
    ) external OnlyLara returns (TentativeDelegation[] memory) {
        // we loop through the nodesList and see check if the node's able to capture thw whole amount
        // if not, we take the next node and so on. We return the TentativeDelegation's until the amount is
        // fully captured
        TentativeDelegation[]
            memory tentativeDelegations = new TentativeDelegation[](nodeCount);
        uint256 tentativeDelegationsCount = 0;
        uint256 totalAmount = amount;
        for (uint256 i = 0; i < nodeCount; i++) {
            address node = nodesList[i];
            try _dpos.getValidator(node) returns (
                DposInterface.ValidatorBasicInfo memory validator
            ) {
                uint256 totalStake = validator.total_stake;

                if (totalStake >= maxValidatorStakeCapacity) {
                    continue;
                }
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
                    ] = TentativeDelegation(
                        node,
                        stakeSlot,
                        nodes[node].rating
                    );
                    tentativeDelegationsCount++;
                }
            } catch Error(string memory reason) {
                revert(reason);
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

    function batchUpdateNodeData(
        IApyOracle.NodeData[] memory data
    ) external override OnlyDataFeed {
        address[] memory nodeAddresses = new address[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            nodeAddresses[i] = data[i].account;
            nodes[nodeAddresses[i]] = data[i];
        }
        nodesList = nodeAddresses;
        nodeCount = nodesList.length;
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

    function setMaxValidatorStakeCapacity(
        uint256 capacity
    ) external OnlyDataFeed {
        maxValidatorStakeCapacity = capacity;
    }

    function sortTentativeDelegationsByRating(
        TentativeDelegation[] memory delegations
    ) private pure returns (TentativeDelegation[] memory) {
        uint256 n = delegations.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (delegations[j].rating > delegations[j + 1].rating) {
                    // Swap delegations[j] and delegations[j + 1]
                    TentativeDelegation memory temp = delegations[j];
                    delegations[j] = delegations[j + 1];
                    delegations[j + 1] = temp;
                }
            }
        }
        return delegations;
    }
}
