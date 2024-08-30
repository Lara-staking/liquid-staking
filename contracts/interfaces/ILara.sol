// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

/**
 * @title ILara
 * @dev This interface defines the methods for the Lara contract
 */
interface ILara {
    /**
     * @dev Event emitted when a user stakes
     * @param user the user who staked
     * @param amount the amount of the stake
     */
    event Staked(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when a snapshot was taken
     * @param totalDelegation the total delegation
     * @param totalRewards the total rewards
     * @param nextSnapshotBlock the block number of the next snapshot
     */
    event SnapshotTaken(
        uint256 indexed totalDelegation, uint256 indexed totalRewards, uint256 indexed nextSnapshotBlock
    );

    /**
     * @dev Event emitted when all protocol level rewards are claimed from the DPOS Contract
     * @param amount the amount of the rewards
     */
    event AllRewardsClaimed(uint256 indexed amount);

    /**
     * @dev Event emitted when redelegation rewards are claimed
     * @param amount the amount of the rewards
     * @param validator the validator to which the rewards are claimed
     */
    event RedelegationRewardsClaimed(uint256 indexed amount, address indexed validator);

    /**
     * Event emitted when an undelegation request is registered
     * @param id the id of the undelegation
     * @param user the user who requested the undelegation
     * @param validator the validator to which the user undelegated
     * @param amount the amount of the undelegation
     */
    event Undelegated(uint64 indexed id, address indexed user, address indexed validator, uint256 amount);

    /**
     * @dev Event emitted when a user confirms an undelegation
     * @param id the id of the undelegation
     * @param user the user who confirmed the undelegation
     */
    event UndelegationConfirmed(uint64 indexed id, address indexed user);

    /**
     * @dev Event emitted when a user cancels an undelegation
     * @param id the id of the undelegation
     * @param user the user who cancelled the undelegation
     */
    event UndelegationCancelled(uint64 indexed id, address indexed user);

    /**
     * @dev Event emitted when Tara is sent
     * @param user the address who sent the Tara
     * @param amount the amount of the Tara sent
     */
    event TaraSent(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when commission is withdrawn for an epoch to the treasury
     * @param user the treasury address
     * @param amount the amount of the commission withdrawn
     */
    event CommissionWithdrawn(address indexed user, uint256 indexed amount);

    /**
     * @dev Event emitted when commission is changed
     * @param newCommission the new commission
     */
    event CommissionChanged(uint256 indexed newCommission);

    /**
     * @dev Event emitted when treasury is changed
     * @param newTreasury the new treasury address
     */
    event TreasuryChanged(address indexed newTreasury);

    /**
     * @dev Function to compound the rewards into the staking contract
     * @param amount the amount to compound
     */
    function compound(uint256 amount) external;

    /**
     * @dev Function to check if a validator is registered
     * @param validator The address of the validator
     * @return A boolean indicating if the validator is registered
     */
    function isValidatorRegistered(address validator) external view returns (bool);

    /**
     * @dev Function to set the commission discounts
     * @dev Only callable by the owner
     * @param staker the staker address
     * @param discount the discount
     */
    function setCommissionDiscounts(address staker, uint32 discount) external;

    /**
     * @notice Setter for epochDuration
     * @param _epochDuration new epoch duration (in seconds)
     */
    function setEpochDuration(uint256 _epochDuration) external;

    /**
     * @dev Function to set the commission
     * @param _commission The new commission
     */
    function setCommission(uint256 _commission) external;

    /**
     * @dev Function to set the treasury address
     * @param _treasuryAddress The new treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external;

    /**
     * @dev Function to set the maximum validator stake capacity
     * @param _maxValidatorStakeCapacity The new maximum validator stake capacity
     */
    function setMaxValidatorStakeCapacity(uint256 _maxValidatorStakeCapacity) external;

    /**
     * @dev Function to set the minimum stake amount
     * @param _minStakeAmount The new minimum stake amount
     */
    function setMinStakeAmount(uint256 _minStakeAmount) external;

    /**
     * @notice Stake function
     * In the stake function, the user sends the amount of TARA tokens he wants to stake.
     * This method takes the payment and mints the stTARA tokens to the user.
     * @notice The tokens are DELEGATED INSTANTLY.
     * @notice The amount that cannot be delegated is returned to the user.
     * @param amount the amount to stake
     */
    function stake(uint256 amount) external payable returns (uint256);

    /**
     * @notice Rebalance method to rebalance the protocol.
     * The method is intended to be called by anyone, at least every epochDuration blocks.
     * In this V0 there is no on-chain trigger or management function for this, will be triggered from outside.
     * The method will call the oracle to get the rebalance list and then redelegate the stake.
     */
    function rebalance() external;

    /**
     * Undelegates the amount from one or more validators.
     * The user needs to provide the amount of stTARA tokens he wants to undelegate. The protocol will burn them.
     * @notice reverts on missing approval for the amount.
     * @param amount the amount of tokens to undelegate
     * @return undelegation_ids The ids of the undelegations done
     */
    function requestUndelegate(uint256 amount) external returns (uint64[] memory undelegation_ids);

    /**
     * Confirm undelegate method to confirm the undelegation of a user from a certain validator.
     * Will fail if called before the undelegation period is over.
     * @param id the id of the undelegation
     * @notice msg.sender is the delegator
     */
    function confirmUndelegate(uint64 id) external;

    /**
     * Cancel undelegate method to cancel the undelegation of a user from a certain validator.
     * The undelegated value will be returned to the origin validator.
     * @param id the id of the undelegation
     */
    function cancelUndelegate(uint64 id) external;

    /**
     * @notice method to create a protocol snapshot.
     * A protocol snapshot can be done once every epochDuration blocks.
     * The method will claim all rewards from the DPOS contract and distribute them to the delegators.
     */
    function snapshot() external;
}
