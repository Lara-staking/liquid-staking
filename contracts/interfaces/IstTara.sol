// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IstTara
 * @dev Interface for the IstTara contract, extending IERC20
 */
interface IstTara is IERC20 {
    /**
     * @dev Function to mint new tokens
     * @param recipient The address to receive the newly minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) external payable;

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
}
