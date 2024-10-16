// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {LaraToken} from "@contracts/LaraToken.sol";
import {veLara} from "@contracts/veLara.sol";
import {LaraStaking} from "@contracts/LaraStaking.sol";

contract DeployLaraStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDR");
        address laraAddress = vm.envAddress("LARA_TOKEN_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        veLara veLaraToken = new veLara(laraAddress);

        console.log("veLara token deployed at address:", address(veLaraToken));

        require(address(veLaraToken.lara()) == laraAddress, "Lara address is not set properly");

        require(veLaraToken.balanceOf(deployerAddress) == 1000000 ether, "veLara balance is not 100000000 ether");

        address stakingContractProxy = Upgrades.deployUUPSProxy(
            "LaraStaking.sol",
            abi.encodeCall(
                LaraStaking.initialize,
                (
                    address(veLaraToken),
                    address(laraAddress),
                    1,
                    4530,
                    11e11,
                    426445 // 6 months
                )
            )
        );

        LaraStaking stakingContract = LaraStaking(payable(stakingContractProxy));

        console.log("Staking contract deployed at address:", address(stakingContract));

        address stakingImplementation = Upgrades.getImplementationAddress(address(stakingContractProxy));

        console.log("Staking implementation deployed at address:", stakingImplementation);

        // add 1M LARA to the staking contract
        veLaraToken.approve(address(stakingContract), 1000000 ether);
        stakingContract.depositRewardTokens(1000000 ether);

        console.log("Deposited 1M LARA to the staking contract");

        vm.stopBroadcast();
    }
}
