// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../contracts/stTara.sol";
import "../../contracts/Lara.sol";
import "../../contracts/ApyOracle.sol";

contract DeployLara is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        address dposAddress = vm.envAddress("DPOS_ADDRESS");
        address treasuryAddress = vm.envAddress("TREASURY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        stTARA stTara = new stTARA();
        ApyOracle apyOracle = new ApyOracle(deployerAddress, dposAddress);
        Lara lara = new Lara(
            address(stTara),
            dposAddress,
            address(apyOracle),
            treasuryAddress
        );
        stTara.setLaraAddress(address(lara));

        // checking if ownership and contract addresses are set properly
        if (stTara.owner() != deployerAddress) {
            revert("stTara owner is not Lara");
        }
        if (lara.owner() != deployerAddress) {
            revert("Lara owner is not deployer");
        }
        // check datafeed
        if (apyOracle._dataFeed() != deployerAddress) {
            revert("ApyOracle datafeed is not deployer");
        }
        if (address(apyOracle._dpos()) != dposAddress) {
            revert("ApyOracle dpos is not dposAddress");
        }
        if (stTara.lara() != address(lara)) {
            revert("stTara lara is not lara");
        }
        if (address(lara.stTaraToken()) != address(stTara)) {
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
