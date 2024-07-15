// (c) 2023-2024, Taraxa, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface MockIDPOS {
    event Delegated(address indexed delegator, address indexed validator, uint256 amount);
    event Undelegated(uint256 indexed id, address indexed delegator, address indexed validator, uint256 amount);
    event UndelegateConfirmed(uint256 indexed id, address indexed delegator, address indexed validator, uint256 amount);
    event UndelegateCanceled(uint256 indexed id, address indexed delegator, address indexed validator, uint256 amount);
    event Redelegated(address indexed delegator, address indexed from, address indexed to, uint256 amount);
    event RewardsClaimed(address indexed account, address indexed validator, uint256 amount);
    event CommissionRewardsClaimed(address indexed account, address indexed validator, uint256 amount);
    event CommissionSet(address indexed validator, uint16 commission);
    event ValidatorRegistered(address indexed validator);
    event ValidatorInfoSet(address indexed validator);

    struct ValidatorBasicInfo {
        // Total number of delegated tokens to the validator
        uint256 total_stake;
        // Validator's reward from delegators rewards commission
        uint256 commission_reward;
        // Validator's commission - max value 10000(precision up to 0.01%)
        uint16 commission;
        // Block number of last commission change
        uint64 last_commission_change;
        // Number of ongoing undelegations from the validator
        uint16 undelegations_count;
        // Validator's owner account
        address owner;
        // Validators description/name
        string description;
        // Validators website endpoint
        string endpoint;
    }

    // Retun value for getValidators method
    struct ValidatorData {
        address account;
        ValidatorBasicInfo info;
    }

    struct UndelegateRequest {
        // Block num, during which UndelegateRequest can be confirmed - during creation it is
        // set to block.number + STAKE_UNLOCK_PERIOD
        uint256 eligible_block_num;
        // Amount of tokens to be unstaked
        uint256 amount;
    }

    // Delegator data
    struct DelegatorInfo {
        // Number of tokens that were staked
        uint256 stake;
        // Number of tokens that were rewarded
        uint256 rewards;
    }

    // Retun value for getDelegations method
    struct DelegationData {
        // Validator's(in case of getDelegations) or Delegator's (in case of getValidatorDelegations) account address
        address account;
        // Delegation info
        DelegatorInfo delegation;
    }

    // Retun value for getUndelegations method
    struct UndelegationData {
        // Number of tokens that were locked
        uint256 stake;
        // block number when it will be unlocked
        uint64 block;
        // Validator address
        address validator;
        // Flag if validator still exists - in case he has 0 stake and 0 rewards, validator is deleted from memory & db
        bool validator_exists;
    }

    // Retun value for getUndelegationsV2 method
    struct UndelegationV2Data {
        // Undelegation data
        UndelegationData undelegation_data;
        // Undelegation id
        uint64 undelegation_id;
    }

    // Delegates tokens to specified validator
    function delegate(address validator) external payable;

    // Registers new validator - validator also must delegate to himself, he can later withdraw his delegation
    function registerValidator(
        address validator,
        bytes memory proof,
        bytes memory vrf_key,
        uint16 commission,
        string calldata description,
        string calldata endpoint
    ) external payable;

    function getTotalDelegation(address delegator) external view returns (uint256 total_delegation);

    // Returns validator basic info (everything except list of his delegators)
    function getValidator(address validator) external view returns (ValidatorBasicInfo memory validator_info);

    // Undelegates <amount> of tokens from specified validator - creates undelegate request
    function undelegateV2(address validator, uint256 amount) external returns (uint256 id);

    function getValidators(uint32 batch) external view returns (ValidatorData[] memory validators, bool end);

    function getValidatorsFor(address owner, uint32 batch)
        external
        view
        returns (ValidatorData[] memory validators, bool end);

    /**
     * @notice Claims staking rewards from all validators (limited by max dag block gas limit) that caller has delegated to
     *
     */
    function claimAllRewards() external;

    function reDelegate(address validator_from, address validator_to, uint256 amount) external;

    // Confirms undelegate request
    function confirmUndelegateV2(address validator, uint256 id) external;

    // Cancel undelegate request
    function cancelUndelegateV2(address validator, uint256 id) external;

    function getUndelegationV2(address delegator, address validator, uint64 undelegation_id)
        external
        view
        returns (UndelegationV2Data memory undelegation_v2);
}
