// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice It is returned if the caller is not authorized
 */
error NotAuthorized();

/**
 * @notice It is returned if reward claim from DPOS fails
 */
error RewardClaimFailed(uint32 batch);

// Errors
error StakeAmountTooLow(uint256 amount, uint256 minAmount);
error StakeValueTooLow(uint256 sentAmount, uint256 targetAmount);
/**
 * @notice It is returned if the delegation to a certain validator fails.
 */
error DelegationFailed(
    address validator,
    address delegator,
    uint256 amount,
    string reason
);
error UndelegationFailed(
    address validator,
    address delegator,
    uint256 amount,
    string reason
);

error RedelegationFailed(
    address from,
    address to,
    uint256 amount,
    string reason
);

error ConfirmUndelegationFailed(
    address delegator,
    address validator,
    uint256 amount,
    string reason
);

error CancelUndelegationFailed(
    address delegator,
    address validator,
    uint256 amount,
    string reason
);
