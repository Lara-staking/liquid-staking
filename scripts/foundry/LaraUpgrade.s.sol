// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import "forge-std/Script.sol";
// import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
// import {IstTara} from "../../contracts/interfaces/IstTara.sol";
// import {Lara} from "../../contracts/Lara.sol";
// import {LaraV2} from "../../contracts/LaraV2.sol";
// import {ApyOracle} from "../../contracts/ApyOracle.sol";

// contract LaraUpgrade is Script {
//     function run() public {
//         vm.startBroadcast();
//         address laraAddress = 0x52a7C8Db4a32016e4b8b6b4b44590C52079f32A9;

//         address implementationAddress = Upgrades.getImplementationAddress(laraAddress);

//         console.log("current implemenetation address: ", implementationAddress);

//         Options memory opts;
//         opts.unsafeSkipStorageCheck = true;

//         Upgrades.upgradeProxy(address(laraAddress), "LaraV2.sol", "", opts);

//         address newImplementationAddress = Upgrades.getImplementationAddress(laraAddress);

//         console.log("new implemenetation address: ", newImplementationAddress);

//         require(implementationAddress != newImplementationAddress, "impl addresses must not match");
//         vm.stopBroadcast();
//     }
// }
