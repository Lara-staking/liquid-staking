// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IApyOracle} from "@contracts/interfaces/IApyOracle.sol";
import {DposInterface} from "@contracts/interfaces/IDPOS.sol";

/**
 * @title ApyOracle
 * @dev This contract implements the IApyOracle interface and provides methods for managing nodes and delegations.
 */
contract ApyOracle is IApyOracle, OwnableUpgradeable, UUPSUpgradeable {
    /// @dev Maximum stake capacity for a validator
    uint256 public maxValidatorStakeCapacity;

    /// @dev Number of nodes
    uint256 public nodeCount;

    /// @dev Data feed address
    address public DATA_FEED;

    /// @dev Lara contract address
    address public lara;

    /// @dev DPOS contract address
    DposInterface public DPOS;

    /// @dev List of nodes
    address[] public nodesList;

    /// @dev Mapping of node data
    mapping(address => IApyOracle.NodeData) public nodes;

    /// @dev Storage gap for future upgrades
    uint256[49] __gap;

    // Event declarations
    event LaraAddressUpdated(address indexed oldLara, address indexed newLara);
    event NodeCountUpdated(uint256 oldNodeCount, uint256 newNodeCount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with the given data feed and DPOS contract addresses.
     * @param dataFeed The address of the data feed contract.
     * @param dpos The address of the DPOS contract.
     */
    function initialize(address dataFeed, address dpos) public initializer {
        require(dataFeed != address(0) && dpos != address(0), "Zero address");

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        DATA_FEED = dataFeed;
        DPOS = DposInterface(dpos);
        maxValidatorStakeCapacity = 80000000 ether;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Modifier to make a function callable only by the data feed contract.
     */
    modifier OnlyDataFeed() {
        require(msg.sender == DATA_FEED, "ApyOracle: caller is not the data feed");
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
        require(_lara != address(0), "Zero address");
        address oldLara = lara;
        lara = _lara;
        emit LaraAddressUpdated(oldLara, _lara);
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
    function getRebalanceList(TentativeDelegation[] memory currentValidators)
        external
        override
        OnlyLara
        returns (TentativeReDelegation[] memory)
    {
        if (currentValidators.length == 0 || nodeCount == 0) {
            return new TentativeReDelegation[](0);
        }
        // order the currentValidators by rating
        TentativeDelegation[] memory orderedValidators = sortTentativeDelegationsByRating(currentValidators);
        TentativeReDelegation[] memory tentativeReDelegations = new TentativeReDelegation[](nodeCount);
        uint256 count = 0;
        for (uint256 i = 0; i < nodeCount; i++) {
            address node = nodesList[i];
            try DPOS.getValidator(node) returns (DposInterface.ValidatorBasicInfo memory validator) {
                uint256 totalStake = validator.total_stake;
                if (totalStake >= maxValidatorStakeCapacity) {
                    continue;
                }
                uint256 availableDelegation = maxValidatorStakeCapacity - totalStake;
                for (uint256 j = 0; j < orderedValidators.length; j++) {
                    if (orderedValidators[j].validator == node) {
                        continue;
                    }
                    if (nodes[nodesList[i]].rating <= nodes[orderedValidators[j].validator].rating) {
                        continue;
                    }
                    if (orderedValidators[j].amount == 0) {
                        continue;
                    }
                    if (availableDelegation > 0) {
                        uint256 redelegatable = 0;
                        if (availableDelegation < orderedValidators[j].amount) {
                            redelegatable = availableDelegation;
                        } else {
                            redelegatable = orderedValidators[j].amount;
                        }
                        tentativeReDelegations[count] = TentativeReDelegation(
                            orderedValidators[j].validator, node, redelegatable, nodes[node].rating
                        );
                        availableDelegation -= redelegatable;
                        orderedValidators[j].amount -= redelegatable;
                        count++;
                    } else {
                        break;
                    }
                }
            } catch Error(string memory reason) {
                revert(reason);
            }
        }
        // Create a new array with the exact length
        TentativeReDelegation[] memory result = new TentativeReDelegation[](count);
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
    function getNodesForDelegation(uint256 amount) external OnlyLara returns (TentativeDelegation[] memory) {
        // we loop through the nodesList and see check if the node's able to capture thw whole amount
        // if not, we take the next node and so on. We return the TentativeDelegation's until the amount is
        // fully captured
        TentativeDelegation[] memory tentativeDelegations = new TentativeDelegation[](nodeCount);
        uint256 tentativeDelegationsCount = 0;
        uint256 totalAmount = amount;
        for (uint256 i = 0; i < nodeCount; i++) {
            address node = nodesList[i];
            try DPOS.getValidator(node) returns (DposInterface.ValidatorBasicInfo memory validator) {
                uint256 totalStake = validator.total_stake;

                if (totalStake >= maxValidatorStakeCapacity) {
                    continue;
                }
                uint256 availableDelegation = maxValidatorStakeCapacity - totalStake;
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
                    tentativeDelegations[tentativeDelegationsCount] =
                        TentativeDelegation(node, stakeSlot, nodes[node].rating);
                    tentativeDelegationsCount++;
                }
            } catch Error(string memory reason) {
                revert(reason);
            }
        }
        // Create a new array with the exact length
        TentativeDelegation[] memory result = new TentativeDelegation[](tentativeDelegationsCount);
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
        uint256 oldNodeCount = nodeCount;
        nodeCount = count;
        emit NodeCountUpdated(oldNodeCount, count);
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
    function getNodeData(address node) external view override returns (IApyOracle.NodeData memory) {
        return nodes[node];
    }

    /**
     * @dev Updates the data of multiple nodes at once.
     * @param data An array of node data.
     */
    function batchUpdateNodeData(IApyOracle.NodeData[] memory data) external override OnlyDataFeed {
        address[] memory nodeAddresses = new address[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            nodeAddresses[i] = data[i].account;
            nodes[nodeAddresses[i]] = data[i];
            emit NodeDataUpdated(nodeAddresses[i], data[i].apy, data[i].rating);
        }
        nodesList = nodeAddresses;
        nodeCount = nodesList.length;
    }

    /**
     * @dev Updates the data of a specific node.
     * @param node The address of the node.
     * @param data The new data of the node.
     */
    function updateNodeData(address node, NodeData memory data) external override OnlyDataFeed {
        require(nodes[node].fromBlock < data.fromBlock, "ApyOracle: fromBlock must be greater than the previous one");
        require(data.fromBlock < data.toBlock, "ApyOracle: fromBlock must be less than toBlock");
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
    function setMaxValidatorStakeCapacity(uint256 capacity) external OnlyDataFeed {
        maxValidatorStakeCapacity = capacity;
        emit MaxValidatorStakeUpdated(capacity);
    }

    /**
     * @dev Sorts an array of tentative delegations by rating.
     * @param delegations The array of tentative delegations to sort.
     * @return The sorted array of tentative delegations.
     */
    function sortTentativeDelegationsByRating(TentativeDelegation[] memory delegations)
        private
        pure
        returns (TentativeDelegation[] memory)
    {
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
