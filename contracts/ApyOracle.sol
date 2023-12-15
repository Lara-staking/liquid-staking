// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol rework with call instead of delegatecall)
pragma solidity 0.8.20;

import "./interfaces/IApyOracle.sol";
import "./interfaces/IDPOS.sol";

/**
 * @title ApyOracle
 * @dev This contract implements the IApyOracle interface and provides methods for managing nodes and delegations.
 */
contract ApyOracle is IApyOracle {
    /**
     * @dev Initializes the contract with the given data feed and DPOS contract addresses.
     * @param dataFeed The address of the data feed contract.
     * @param dpos The address of the DPOS contract.
     */
    constructor(address dataFeed, address dpos) {
        DATA_FEED = dataFeed;
        DPOS = DposInterface(dpos);
    }

    uint256 public maxValidatorStakeCapacity = 80000000 ether;

    uint256 public nodeCount;

    address public immutable DATA_FEED;

    address public lara;

    DposInterface public immutable DPOS;

    address[] public nodesList;

    mapping(address => IApyOracle.NodeData) public nodes;

    /**
     * @dev Modifier to make a function callable only by the data feed contract.
     */
    modifier OnlyDataFeed() {
        require(
            msg.sender == DATA_FEED,
            "ApyOracle: caller is not the data feed"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only by the Lara contract.
     */
    modifier OnlyLara() {
        require(msg.sender == lara, "ApyOracle: caller is not Lara");
        _;
    }

    /**
     * @dev Sets the Lara contract address.
     * @param _lara The address of the Lara contract.
     */
    function setLara(address _lara) external OnlyDataFeed {
        lara = _lara;
    }

    /**
     * @dev Returns the number of nodes.
     * @return The number of nodes.
     */
    function getNodeCount() external view override returns (uint256) {
        return nodeCount;
    }

    /**
     * @dev Returns a list of tentative re-delegations based on the current validators.
     * @param currentValidators The current validators.
     * @return An array of tentative re-delegations.
     */
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
            try DPOS.getValidator(node) returns (
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
     * @dev Returns a list of nodes that can be delegated to, along with the amount that can be delegated to each node.
     * @param amount The amount to be delegated.
     * @return An array of tentative delegations.
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
            try DPOS.getValidator(node) returns (
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

    /**
     * @dev Updates the node count.
     * @param count The new node count.
     */
    function updateNodeCount(uint256 count) external override OnlyDataFeed {
        nodeCount = count;
    }

    /**
     * @dev Returns the address of the data feed contract.
     * @return The address of the data feed contract.
     */
    function getDataFeedAddress() external view returns (address) {
        return DATA_FEED;
    }

    /**
     * @dev Returns the data of a specific node.
     * @param node The address of the node.
     * @return The data of the node.
     */
    function getNodeData(
        address node
    ) external view override returns (IApyOracle.NodeData memory) {
        return nodes[node];
    }

    /**
     * @dev Updates the data of multiple nodes at once.
     * @param data An array of node data.
     */
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

    /**
     * @dev Updates the data of a specific node.
     * @param node The address of the node.
     * @param data The new data of the node.
     */
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

    /**
     * @dev Sets the maximum stake capacity for a validator.
     * @param capacity The new maximum stake capacity.
     */
    function setMaxValidatorStakeCapacity(
        uint256 capacity
    ) external OnlyDataFeed {
        maxValidatorStakeCapacity = capacity;
    }

    /**
     * @dev Sorts an array of tentative delegations by rating.
     * @param delegations The array of tentative delegations to sort.
     * @return The sorted array of tentative delegations.
     */
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
