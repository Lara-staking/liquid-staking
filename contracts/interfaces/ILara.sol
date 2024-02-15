// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import "./IApyOracle.sol";
import "./ILaraBase.sol";

import "../libs/Utils.sol";

/**
 * @title ILara
 * @dev This interface defines the methods for the Lara contract
 */
interface ILara is ILaraBase {
    /**
     * @dev Event emitted when a user stakes
     */
    event Staked(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when a user delegates
     */
    event Delegated(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when an epoch starts
     */
    event SnapshotTaken(
        uint256 indexed totalDelegation,
        uint256 indexed totalRewards,
        uint256 indexed nextSnapshotBlock
    );

    /**
     * @dev Event emitted when all rewards are claimed
     */
    event AllRewardsClaimed(uint256 indexed amount);

    /**
     * @dev Event emitted when redelegation rewards are claimed
     */
    event RedelegationRewardsClaimed(
        uint256 indexed amount,
        address indexed validator
    );

    /**
     * @dev Event emitted when a user undelegates
     */
    event Undelegated(
        address indexed user,
        address indexed validator,
        uint256 indexed amount
    );

    /**
     * @dev Event emitted when Tara is sent
     */
    event TaraSent(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when a stake is removed
     */
    event StakeRemoved(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when commission is withdrawn
     */
    event CommissionWithdrawn(address indexed user, uint256 indexed amount);

    /**
     * @dev Function to check if a validator is registered
     * @param validator The address of the validator
     * @return A boolean indicating if the validator is registered
     */
    function isValidatorRegistered(
        address validator
    ) external view returns (bool);

    /**
     * @dev Function to get the validator array of the Lara contract
     * @return An array of validator addresses
     */
    function getValidators() external view returns (address[] memory);

    /**
     * @dev Function to set the epoch duration
     * @param _epochDuration The duration of the epoch
     */
    function setEpochDuration(uint256 _epochDuration) external;

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
     * @dev Function to delegate a certain amount to validators
     * @param amount The amount to delegate
     */
    function delegateToValidators(uint256 amount) external returns (uint256);

    /**
     * @dev Function for a user to stake a certain amount
     * @param amount The amount to stake
     */
    function stake(uint256 amount) external payable returns (uint256);

    /**
     * @notice Rebalance method to rebalance the protocol.
     * The method is intended to be called by anyone in between epochs.
     * In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
     * The method will call the oracle to get the rebalance list and then redelegate the stake.
     */
    function rebalance() external;

    // /**
    //  * @dev Function for a user to remove a certain amount of stake
    //  * @param amount The amount of stake to remove
    //  */
    // function unstake(uint256 amount) external;

    /**
     * @dev Function for a user to request undelegation of a certain amount
     * @param amount The amount to undelegate
     */
    function requestUndelegate(address validator, uint256 amount) external;

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

    // /**
    //  * @dev Function to start an epoch
    //  */
    // function startEpoch() external;

    // /**
    //  * @dev Function to end an epoch
    //  */
    // function endEpoch() external;

    function snapshot() external;
}
