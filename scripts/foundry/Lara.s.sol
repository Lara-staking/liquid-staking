// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../../contracts/stTara.sol";
import "../../contracts/Lara.sol";
import "../../contracts/LaraFactory.sol";
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
        LaraFactory laraFactory = new LaraFactory(
            address(stTara),
            dposAddress,
            address(apyOracle),
            treasuryAddress
        );
        stTara.setLaraFactory(address(laraFactory));
        apyOracle.setLaraFactory(address(laraFactory));

        // checking if ownership and contract addresses are set properly
        if (stTara.owner() != deployerAddress) {
            revert("stTara owner is not Lara");
        }
        if (laraFactory.owner() != deployerAddress) {
            revert("Lara owner is not deployer");
        }
        // check datafeed
        if (apyOracle.DATA_FEED() != deployerAddress) {
            revert("ApyOracle datafeed is not deployer");
        }
        if (address(apyOracle.DPOS()) != dposAddress) {
            revert("ApyOracle dpos is not dposAddress");
        }
        if (address(stTara.laraFactory()) != address(laraFactory)) {
            revert("stTara lara is not lara");
        }
        if (address(laraFactory.treasuryAddress()) != treasuryAddress) {
            revert("lara treasury is not treasuryAddress");
        }
        if (address(apyOracle.laraFactory()) != address(laraFactory)) {
            revert("apyOracle lara is not lara");
        }
        if (address(laraFactory.stTaraToken()) != address(stTara)) {
            revert("lara stTara is not stTara");
        }
        if (address(laraFactory.apyOracle()) != address(apyOracle)) {
            revert("lara oracle is not apyOracle");
        }
        if (address(laraFactory.dposContract()) != dposAddress) {
            revert("lara dpos is not dposAddress");
        }

        vm.stopBroadcast();
    }
}
