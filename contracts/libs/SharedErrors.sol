// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

/**
 * @notice It is returned if the caller is not authorized
 */
error NotAuthorized();

/**
 * @notice It is returned if reward claim from DPOS fails
 */
error RewardClaimFailed(string reason);

error StakeAmountTooLow(uint256 amount, uint256 minAmount);
error StakeValueTooLow(uint256 sentAmount, uint256 targetAmount);
/**
 * @notice It is returned if the delegation to a certain validator fails.
 */
error DelegationFailed(address validator, address delegator, uint256 amount, string reason);

/**
 * @notice It is returned if the undelegation is not found.
 */
error UndelegationNotFound(address delegator, uint256 id);

/**
 * @notice It is returned if the undelegation from a certain validator fails.
 */
error UndelegationFailed(address validator, address delegator, uint256 amount);

/**
 * @notice It is returned if the redelegation from a certain validator fails.
 */
error RedelegationFailed(address from, address to, uint256 amount, string reason);

/**
 * @notice It is returned if the undelegation confirmation from a certain validator fails.
 */
error ConfirmUndelegationFailed(address delegator, address validator, uint256 amount, string reason);

/**
 * @notice It is returned if the undelegation cancellation from a certain validator fails.
 */
error CancelUndelegationFailed(address delegator, address validator, uint256 amount, string reason);

/**
 * @notice It is returned if the epoch duration was not met and the method to end was called.
 */
error EpochDurationNotMet(uint256 lastEpochStart, uint256 currentBlockNumber, uint256 epochDuration);

/**
 * @notice It is returned if the user doesn't have enough balance of stTARA.
 */
error NotEnoughStTARA(address user, uint256 balance, uint256 amount);

/**
 * @notice It is returned if the undelegations don't match the amount.
 */
error UndelegationsNotMatching(uint256 undelegations, uint256 amount);
