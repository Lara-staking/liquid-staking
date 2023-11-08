// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILara {
    event Staked(address indexed user, uint256 amount);
    event Delegated(address indexed user, uint256 amount);
    event EpochStarted(uint256 totalEpochDelegation, uint256 timestamp);
    event RewardsClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event EpochEnded(
        uint256 totalEpochDelegation,
        uint256 totalEpochReward,
        uint256 timestamp
    );
    event Undelegated(
        address indexed user,
        address indexed validator,
        uint256 amount
    );
    event TaraSent(address indexed user, uint256 amount, uint256 blockNumber);
    event StakeRemoved(address indexed user, uint256 amount);
    event CommissionWithdrawn(address indexed user, uint256 amount);
    event CompoundChanged(address indexed user, bool value);
    event CommissionChanged(uint256 newCommission);
    event TreasuryChanged(address indexed newTreasury);

    function getDelegatorAtIndex(uint256 index) external view returns (address);

    function isValidatorRegistered(
        address validator
    ) external view returns (bool);

    function setEpochDuration(uint256 _epochDuration) external;

    function setCompound(address user, bool value) external;

    function setMaxValidatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external;

    function setMinStakeAmount(uint256 _minStakeAmount) external;

    function stake(uint256 amount) external payable;

    function removeStake(uint256 amount) external;

    function reDelegate(address from, address to, uint256 amount) external;

    function confirmUndelegate(address validator, uint256 amount) external;

    function cancelUndelegate(address validator, uint256 amount) external;

    function requestUndelegate(uint256 amount) external;

    function claimRewards() external;

    function startEpoch() external;

    function endEpoch() external;
}
