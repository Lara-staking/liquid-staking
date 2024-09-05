// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";

contract Multicall2 is Multicall {
    constructor() {}
}

contract DeployMulticall is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Multicall2 mc = new Multicall2();

        console.log("Multicall address: %s", address(mc));

        vm.stopBroadcast();
    }
}
