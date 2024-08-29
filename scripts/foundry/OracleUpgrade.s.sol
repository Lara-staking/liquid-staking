// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import "forge-std/Script.sol";
// import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
// import {IstTara} from "../../contracts/interfaces/IstTara.sol";
// import {ApyOracle} from "../../contracts/ApyOracle.sol";
// import {ApyOracleV2} from "../../contracts/ApyOracleV2.sol";

// contract OracleUpgrade is Script {
//     function run() public {
//         vm.startBroadcast();
//         address oracleAddress = 0x4bFCdc5a4166405D9503437523832Bbd2DC759Ef;

//         address implementationAddress = Upgrades.getImplementationAddress(oracleAddress);

//         console.log("current implemenetation address: ", implementationAddress);

//         Options memory opts;
//         opts.unsafeSkipStorageCheck = true;

//         Upgrades.upgradeProxy(address(oracleAddress), "ApyOracleV2.sol", "", opts);

//         address newImplementationAddress = Upgrades.getImplementationAddress(oracleAddress);

//         console.log("new implemenetation address: ", newImplementationAddress);

//         require(implementationAddress != newImplementationAddress, "impl addresses must not match");
//         vm.stopBroadcast();
//     }
// }
