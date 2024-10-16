// SPDX-License-Identifier: MIT
// Security contact: dao@tlara.xyz
pragma solidity 0.8.20;

/**
 * @title IstTara
 * @dev Interface for the IstTara contract, extending IERC20
 */
interface ISnapshot {
    /**
     * @dev Function to take a snapshot of the tracked contract internal values(most notably balances and contract deposits)
     * @return the snapshot id
     */
    function snapshot() external returns (uint256);
}
