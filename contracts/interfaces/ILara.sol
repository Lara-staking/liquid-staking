// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILara {
    // Events
    event Staked(address indexed user, uint256 amount);
    event Delegated(
        address indexed user,
        address indexed validator,
        uint256 amount,
        uint256 timestamp
    );
    event RewardsAccrued(
        address indexed delegator,
        address indexed validator,
        uint256 amount,
        uint256 stakeDuration
    );

    event RewardsClaimed(
        address indexed delegator,
        address indexed validator,
        uint256 epochLength,
        uint256 amount
    );

    event Undelegated(
        address indexed delegator,
        address indexed validator,
        uint256 amount
    );

    struct IndividualDelegation {
        address validator;
        uint256 amount;
        uint256 timestamp;
    }

    struct ValidatorDelegation {
        address delegator;
        uint256 amount;
        uint256 delegationTimestamp;
        uint256 lastClaimedTimestamp;
    }

    struct Reward {
        address validator;
        uint256 amount;
        uint256 length;
    }

    function getStakedAmount(address user) external view returns (uint256);

    function getFirstDelegationToValidator(
        address validator
    ) external view returns (uint256);

    function getIndividualDelegations(
        address user
    ) external view returns (IndividualDelegation[] memory);

    function getValidatorDelegations(
        address validator
    ) external view returns (ValidatorDelegation[] memory);

    function getRewards(address user) external view returns (Reward[] memory);

    function getProtocolTotalStakeAtValdiator(
        address validator
    ) external view returns (uint256);

    function stake(uint256 amount) external payable returns (uint256);

    function accrueRewardsForDelegator(address delegator) external;

    function claimRewards(address delegator) external;

    function compound(address delegator) external;

    function unstake(uint256 amount) external;

    function setMaxValidatorStakeCapacity(
        uint256 _maxValidatorStakeCapacity
    ) external;

    function setMinStakeAmount(uint256 _minStakeAmount) external;
}
