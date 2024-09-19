// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {StakedNativeAsset} from "../../contracts/StakedNativeAsset.sol";
import {Lara} from "../../contracts/Lara.sol";
import {ApyOracle} from "../../contracts/ApyOracle.sol";

contract DeployLara is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        address dposAddress = vm.envAddress("DPOS_ADDRESS");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        StakedNativeAsset stTaraInstance = new StakedNativeAsset();
        console.log("stTara address:", address(stTaraInstance));
        address oracleProxy = Upgrades.deployUUPSProxy(
            "ApyOracle.sol", abi.encodeCall(ApyOracle.initialize, (deployerAddress, dposAddress))
        );
        console.log("oracleProxy address:", oracleProxy);
        ApyOracle apyOracle = ApyOracle(oracleProxy);
        address oracleImplementation = Upgrades.getImplementationAddress(oracleProxy);
        console.log("oracleImplementation address:", oracleImplementation);
        address laraProxy = Upgrades.deployUUPSProxy(
            "Lara.sol",
            abi.encodeCall(Lara.initialize, (address(stTaraInstance), dposAddress, address(apyOracle), treasuryAddress))
        );
        console.log("laraProxy address:", laraProxy);
        Lara lara = Lara(payable(laraProxy));
        address laraImplementation = Upgrades.getImplementationAddress(laraProxy);
        console.log("laraImplementation address:", laraImplementation);
        stTaraInstance.setLaraAddress(address(lara));
        apyOracle.setLara(address(lara));

        // checking if ownership and contract addresses are set properly
        if (stTaraInstance.owner() != deployerAddress) {
            revert("stTara owner is not Lara");
        }
        if (lara.owner() != deployerAddress) {
            revert("Lara owner is not deployer");
        }
        // check datafeed
        if (apyOracle.DATA_FEED() != deployerAddress) {
            revert("ApyOracle datafeed is not deployer");
        }
        if (address(apyOracle.DPOS()) != dposAddress) {
            revert("ApyOracle dpos is not dposAddress");
        }
        if (stTaraInstance.lara() != address(lara)) {
            revert("stTara lara is not lara");
        }
        if (address(lara.treasuryAddress()) != treasuryAddress) {
            revert("lara treasury is not treasuryAddress");
        }
        if (address(apyOracle.lara()) != address(lara)) {
            revert("apyOracle lara is not lara");
        }
        if (address(lara.stTaraToken()) != address(stTaraInstance)) {
            revert("lara stTara is not stTara");
        }
        if (address(lara.apyOracle()) != address(apyOracle)) {
            revert("lara oracle is not apyOracle");
        }
        if (address(lara.dposContract()) != dposAddress) {
            revert("lara dpos is not dposAddress");
        }

        vm.stopBroadcast();
    }
}
