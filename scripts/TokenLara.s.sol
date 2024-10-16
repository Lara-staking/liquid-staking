// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {LaraToken} from "@contracts/LaraToken.sol";

contract DeployLaraToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        LaraToken lara = new LaraToken(treasuryAddress);

        // checking if ownership and contract addresses are set properly
        if (lara.treasuryAddress() != treasuryAddress) {
            revert("Lara treasury address is not set properly");
        }
        // check if deployet got the minted supply
        if (lara.balanceOf(deployerAddress) != 1000000000 ether) {
            revert("Lara balance is not 1000000000 ether");
        }

        // send back 10% of the supply to laraToken for Presale
        lara.transfer(address(lara), lara.totalSupply() / 10);

        // check if laraToken has 10% of the supply
        if (lara.balanceOf(address(lara)) != lara.totalSupply() / 10) {
            revert("Lara balance is not 10% of total supply");
        }

        //start the presale
        // lara.startPresale();

        vm.stopBroadcast();
    }
}
