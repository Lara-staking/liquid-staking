// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {WrappedStTara} from "@contracts/WstTara.sol";

contract DeployWstTara is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address stTaraAddress = 0x37Df886BE517F9c75b27Cb70dac0D61432C92FBE;

        WrappedStTara wstTara = new WrappedStTara(stTaraAddress);

        console.log("WstTara deployed at", address(wstTara));

        vm.stopBroadcast();
    }
}
