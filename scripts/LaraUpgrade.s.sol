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
//         address laraAddress = 0x397F45dCaC0DC00cb927d8eCE7d449F726A517cF;

//         address implementationAddress = Upgrades.getImplementationAddress(laraAddress);

//         console.log("current implemenetation address: ", implementationAddress);

//         Options memory opts;

//         Upgrades.upgradeProxy(address(laraAddress), "LaraV2.sol", "", opts);

//         address newImplementationAddress = Upgrades.getImplementationAddress(laraAddress);

//         console.log("new implemenetation address: ", newImplementationAddress);

//         require(implementationAddress != newImplementationAddress, "impl addresses must not match");
//         vm.stopBroadcast();
//     }
// }
