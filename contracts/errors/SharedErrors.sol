// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice It is returned if the caller is not authorized
 */
error NotAuthorized();

/**
 * @notice It is returned if reward claim from DPOS fails
 */
error RewardClaimFailed();

// Errors
error StakeAmountTooLow(uint256 amount, uint256 minAmount);
error StakeValueTooLow(uint256 sentAmount, uint256 targetAmount);
/**
 * @notice It is returned if the delegation to a certain validator fails.
 */
error DelegationFailed(address validator, address delegator, uint256 amount);
