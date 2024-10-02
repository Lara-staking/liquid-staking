// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IstTara} from "@contracts/interfaces/IstTara.sol";
import {Lara} from "@contracts/Lara.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";

contract DeployLara is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        address dposAddress = vm.envAddress("DPOS_ADDRESS");
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        address stTaraAddress = vm.envAddress("STTARA_ADDRESS");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        address laraProxy = Upgrades.deployUUPSProxy(
            "Lara.sol", abi.encodeCall(Lara.initialize, (stTaraAddress, dposAddress, oracleAddress, treasuryAddress))
        );
        Lara lara = Lara(payable(laraProxy));
        IstTara stTara = IstTara(stTaraAddress);
        stTara.setLaraAddress(address(lara));

        // checking if ownership and contract addresses are set properly
        if (lara.owner() != deployerAddress) {
            revert("Lara owner is not deployer");
        }
        // check datafeed
        if (address(lara.stTaraToken()) != address(stTara)) {
            revert("lara stTara is not stTara");
        }
        if (address(lara.dposContract()) != dposAddress) {
            revert("lara dpos is not dposAddress");
        }

        vm.stopBroadcast();
    }
}
