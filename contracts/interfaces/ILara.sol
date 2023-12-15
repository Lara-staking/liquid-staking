// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import "./IApyOracle.sol";

/**
 * @title ILara
 * @dev This interface defines the methods for the Lara contract
 */
interface ILara {
    /**
     * @dev Event emitted when a user stakes
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when a user delegates
     */
    event Delegated(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when an epoch starts
     */
    event EpochStarted(
        uint256 indexed totalEpochDelegation,
        uint256 indexed timestamp
    );

    /**
     * @dev Event emitted when all rewards are claimed
     */
    event AllRewardsClaimed(uint256 indexed amount);

    /**
     * @dev Event emitted when redelegation rewards are claimed
     */
    event RedelegationRewardsClaimed(uint256 amount, address validator);

    /**
     * @dev Event emitted when rewards are claimed
     */
    event RewardsClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when an epoch ends
     */
    event EpochEnded(
        uint256 totalEpochDelegation,
        uint256 totalEpochReward,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a user undelegates
     */
    event Undelegated(
        address indexed user,
        address indexed validator,
        uint256 amount
    );

    /**
     * @dev Event emitted when Tara is sent
     */
    event TaraSent(address indexed user, uint256 amount, uint256 blockNumber);

    /**
     * @dev Event emitted when a stake is removed
     */
    event StakeRemoved(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when commission is withdrawn
     */
    event CommissionWithdrawn(address indexed user, uint256 amount);

    /**
     * @dev Event emitted when compound is changed
     */
    event CompoundChanged(address indexed user, bool value);

    /**
     * @dev Event emitted when commission is changed
     */
    event CommissionChanged(uint256 newCommission);

    /**
     * @dev Event emitted when treasury is changed
     */
    event TreasuryChanged(address indexed newTreasury);

    /**
     * @dev Function to get the delegator at a specific index
     * @param index The index of the delegator
     * @return The address of the delegator
     */
    function getDelegatorAtIndex(uint256 index) external view returns (address);

    /**
     * @dev Function to check if a validator is registered
     * @param validator The address of the validator
     * @return A boolean indicating if the validator is registered
     */
    function isValidatorRegistered(
        address validator
    ) external view returns (bool);

    /**
     * @dev Function to set the epoch duration
     * @param _epochDuration The duration of the epoch
     */
    function setEpochDuration(uint256 _epochDuration) external;

    /**
     * @dev Function to set the compound value
     * @param value The new compound value
     */
    function setCompound(bool value) external;

    /**
     * @dev Function to set the maximum validator stake capacity
     * @param _maxValidatorStakeCapacity The new maximum validator stake capacity
     */
    function setMaxValidatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external;

    /**
     * @dev Function to set the minimum stake amount
     * @param _minStakeAmount The new minimum stake amount
     */
    function setMinStakeAmount(uint256 _minStakeAmount) external;

    /**
     * @dev Function for a user to stake a certain amount
     * @param amount The amount to stake
     */
    function stake(uint256 amount) external payable;

    /**
     * @dev Function for a user to remove a certain amount of stake
     * @param amount The amount of stake to remove
     */
    function removeStake(uint256 amount) external;

    /**
     * @dev Function for a user to confirm undelegation of a certain amount
     * @param validator The address of the validator
     * @param amount The amount to undelegate
     */
    function confirmUndelegate(address validator, uint256 amount) external;

    /**
     * @dev Function for a user to cancel undelegation of a certain amount
     * @param validator The address of the validator
     * @param amount The amount to undelegate
     */
    function cancelUndelegate(address validator, uint256 amount) external;

    /**
     * @dev Function for a user to request undelegation of a certain amount
     * @param amount The amount to undelegate
     */
    function requestUndelegate(uint256 amount) external;

    /**
     * @dev Function to get validators for a certain amount
     * @param amount The amount
     * @return An array of tentative delegations
     */
    function getValidatorsForAmount(
        uint256 amount
    ) external returns (IApyOracle.TentativeDelegation[] memory);

    /**
     * @dev Function for a user to claim rewards
     */
    function claimRewards() external;

    /**
     * @dev Function to start an epoch
     */
    function startEpoch() external;

    /**
     * @dev Function to end an epoch
     */
    function endEpoch() external;

    /**
     * @dev Function to rebalance
     */
    function rebalance() external;
}
