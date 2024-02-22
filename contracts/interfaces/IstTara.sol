// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Utils} from "../libs/Utils.sol";
import {IFactoryGoverned} from "./IFactoryGoverned.sol";

/**
 * @title IstTara
 * @dev Interface for the IstTara contract, extending IERC20
 */
interface IstTara is IERC20, IFactoryGoverned {
    /**
     * @dev Function to mint new tokens
     * @param recipient The address to receive the newly minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(
        address recipient,
        uint256 amount,
        address originLaraInstance
    ) external;

    /**
     * @dev Function to burn tokens from a specific address
     * @param user The address from which tokens will be burnt
     * @param amount The amount of tokens to burn
     */
    function burn(address user, uint256 amount) external;
}
