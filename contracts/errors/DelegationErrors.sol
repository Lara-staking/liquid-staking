// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice It is returned if the delegation to a certain validator fails.
 */
error DelegationFailed(
    address validator,
    address delegator,
    uint256 amount,
    string reason
);

/**
 * @notice It is returned if the reward claim from a certain validator fails.
 */
error RewardClaimFailed(address validator);
