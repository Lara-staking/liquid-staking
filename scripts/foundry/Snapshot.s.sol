// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IstTara} from "../../contracts/interfaces/IstTara.sol";
import {Lara} from "../../contracts/Lara.sol";
import {ApyOracle} from "../../contracts/ApyOracle.sol";

contract Snapshot is Script {
    function run() public {
        vm.startBroadcast();
        address laraAddress = 0x017bcd6c818baeee80809E21786fcAA595d75eB2;

        Lara lara = Lara(payable(laraAddress));

        vm.stopBroadcast();
    }
}
