// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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

        vm.stopBroadcast();
    }
}
