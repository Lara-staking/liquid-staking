// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../../contracts/wTARA.sol";

contract DeployWTara is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
        WTARA9 wtara = new WTARA9();

        vm.stopBroadcast();
    }
}
