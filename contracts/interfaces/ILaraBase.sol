// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import "../libs/Utils.sol";

/**
 * @title ILara
 * @dev This interface defines the methods for the Lara contract
 */
interface ILaraBase {
    /**
     * @dev Event emitted when commission is changed
     */
    event CommissionChanged(uint256 indexed newCommission);

    /**
     * @dev Event emitted when treasury is changed
     */
    event TreasuryChanged(address indexed newTreasury);

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
}
