// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IstTara
 * @dev Interface for the IstTara contract, extending IERC20
 */
interface ISnapshot {
    /**
     * @dev Function to take a snapshot of the contract balances
     * @return the snapshot id
     */
    function snapshot() external returns (uint256);
}
