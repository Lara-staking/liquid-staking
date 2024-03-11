// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import "../../contracts/ERC20Wrapper.sol";

contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.envAddress("DEPLOYER_ADDR");
        vm.startBroadcast(deployerPrivateKey);
        // deploy TARAPEPE ERC20
        ERC20Wrapper tarapepe = new ERC20Wrapper("TARAPEPE", "TPEPE");
        require(
            tarapepe.balanceOf(deployer) == 1000000000 ether,
            "TARAPEPE balance incorrect"
        );

        // deploy T1 test token 1
        ERC20Wrapper t1 = new ERC20Wrapper("T1", "T1");
        require(
            t1.balanceOf(deployer) == 1000000000 ether,
            "T1 balance incorrect"
        );

        // deploy T2 test token 2
        ERC20Wrapper t2 = new ERC20Wrapper("T2", "T2");
        require(
            t2.balanceOf(deployer) == 1000000000 ether,
            "T2 balance incorrect"
        );

        // deploy T3 test token 3
        ERC20Wrapper t3 = new ERC20Wrapper("T3", "T3");
        require(
            t3.balanceOf(deployer) == 1000000000 ether,
            "T3 balance incorrect"
        );
        vm.stopBroadcast();
    }
}
