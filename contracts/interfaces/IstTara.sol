// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISnapshot} from "./ISnapshot.sol";
/**
 * @title IstTara
 * @dev Interface for the IstTara contract, extending IERC20
 * This interface is used to handle the stTARA and wstTARA balances of users and contracts,
 * handling more complex scenarios as yield-bearing contracts and non-yield bearing contracts.
 * Example scenario:
 *
 * User 1:
 * - stTARA balance: 2.5M
 * - Total stTARA supply: 2.5M
 *
 * User 2:
 * - stTARA balance: 5M
 * - Total stTARA supply: 7.5M
 *
 * Both users deposit their stTARA into a non-yield-bearing contract.
 *
 * Uniswap V3 pool:
 * - stTARA balance: 7.5M
 * - Total stTARA supply: 7.5M
 * - All yields should be forwarded from the V3 pool contract to the depsitors.
 *
 * In this scenario, cumulativeBalanceOfAt(address, snapshotId) would return 0 for all non-yield bearing contracts,
 * while returning 2.5M and 7.5M for users 1 and 2 respectively.
 */

interface IstTara is IERC20, ISnapshot {
    /**
     * @dev Function to mint new tokens
     * @param recipient The address to receive the newly minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) external;

    /**
     * @dev Function to burn tokens from a specific address
     * @param user The address from which tokens will be burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address user, uint256 amount) external;

    /**
     * @dev Function to set the Lara contract address
     * @param laraAddress The address of the Lara contract
     */
    function setLaraAddress(address laraAddress) external;

    /**
     * @dev Function to set the yield bearing contract address
     * @param contractAddress The address of the yield bearing contract
     * Yield bearing contracts are contracts that's balance attribute to stTARA rewards.
     */
    function setYieldBearingContract(address contractAddress) external;

    /**
     * @dev Function to get the cumulative balance of a user between both stTARA and wstTARA
     * @param user The address of the user
     * @return The cumulative balance of the user
     * @notice In case the user is the wstTARA contract, the function will return the wstTARA balance of the wstTARA contract,
     * ignoring the stTARA balance of the wstTARA contract(locked tokens).
     */
    function cumulativeBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Function to get the cumulative balance of a user between both stTARA and wstTARA at a specific snapshot ID
     * @param user The address of the user
     * @param snapshotId The snapshot ID
     * @return The cumulative balance of the user at the snapshot ID
     * @notice In case the user is the wstTARA contract, the function will return the wstTARA balance of the wstTARA contract,
     * ignoring the stTARA balance of the wstTARA contract(locked tokens).
     */
    function cumulativeBalanceOfAt(address user, uint256 snapshotId) external view returns (uint256);

    /**
     * @dev Function to get the total supply at a specific snapshot ID
     * @param snapshotId The snapshot ID
     * @return The total supply at the snapshot ID
     */
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
}
