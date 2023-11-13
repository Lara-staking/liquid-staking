// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IstTara is IERC20 {
    function mint(address recipient, uint256 amount) external payable;

    function burn(address user, uint256 amount) external;

    function setLaraAddress(address laraAddress) external;
}
