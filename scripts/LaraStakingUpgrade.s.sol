// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IstTara} from "@contracts/interfaces/IstTara.sol";
import {Lara} from "@contracts/Lara.sol";
import {LaraStaking} from "@contracts/LaraStaking.sol";
// import {LaraStakingV2} from "@contracts/LaraStakingV2.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";

contract LaraStakingUpgrade is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address laraStakingAddress = 0x0d4dBAeEa3Fd95a73E11724aAB2d2Dc3E969E177;

        address implementationAddress = Upgrades.getImplementationAddress(laraStakingAddress);

        console.log("current implemenetation address: ", implementationAddress);

        Options memory opts;

        Upgrades.upgradeProxy(address(laraStakingAddress), "LaraStakingV2.sol", "", opts);

        address newImplementationAddress = Upgrades.getImplementationAddress(laraStakingAddress);

        console.log("new implemenetation address: ", newImplementationAddress);

        require(implementationAddress != newImplementationAddress, "impl addresses must not match");
        vm.stopBroadcast();
    }
}
