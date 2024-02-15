// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import "./ILaraBase.sol";

import "../libs/Utils.sol";

/**
 * @title ILara
 * @dev This interface defines the methods for the Lara contract
 */
interface ILaraFactory is ILaraBase {
    /**
     * Emitted when a new Lara contract is created
     * @param laraAddress The address of the new Lara contract
     * @param creator The address of the creator of the new Lara contract
     */
    event LaraCreated(address indexed laraAddress, address indexed creator);

    /**
     * Creates a new Lara contract in case the delegator does not have one
     */
    function createLara() external returns (address payable);

    /**
     * Deactivates the Lara contract of the caller
     */
    function deactivateLara() external;
}
