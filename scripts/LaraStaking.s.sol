// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {LaraToken} from "@contracts/LaraToken.sol";
import {veLara} from "@contracts/veLara.sol";
import {LaraStaking} from "@contracts/LaraStaking.sol";

contract DeployLaraStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("MAINNET_DEPLOYER_ADDR");
        address laraAddress = vm.envAddress("MAINNET_LARA_TOKEN_ADDRESS");
        address treasuryAddress = vm.envAddress("MAINNET_TREASURY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        veLara veLaraToken = veLara(0x9c3cEA6d32853D14f0dd641eED2960F1d6D847d8);

        uint256 totalVeLaraSupply = 1000000000 ether;

        console.log("veLara token deployed at address:", address(veLaraToken));

        require(address(veLaraToken.lara()) == laraAddress, "Lara address is not set properly");

        require(veLaraToken.balanceOf(deployerAddress) == totalVeLaraSupply, "veLara balance is not 1000000000 ether");

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

        LaraStaking stakingContract = LaraStaking(payable(0x9B859bEc39B47C8d9C1459046a32d76B1A6883C1));

        console.log("Staking contract deployed at address:", address(stakingContract));

        address stakingImplementation = Upgrades.getImplementationAddress(address(stakingContractProxy));

        console.log("Staking implementation deployed at address:", stakingImplementation);

        uint256 rewardTokensAmount = 1000000 ether;
        // add 1M LARA to the staking contract
        veLaraToken.approve(address(stakingContract), rewardTokensAmount);
        stakingContract.depositRewardTokens(rewardTokensAmount);

        console.log("Deposited 1M veLARA to the staking contract");

        require(
            veLaraToken.balanceOf(address(stakingContract)) == rewardTokensAmount,
            "Staking contract balance is not 1M veLARA"
        );

        // send the rest of the veLARA to the treasury address
        veLaraToken.transfer(treasuryAddress, veLaraToken.balanceOf(address(deployerAddress)));

        console.log("Sent the rest of the veLARA to the treasury address");

        // verify the balance of the treasury address
        console.log("Treasury address balance:", veLaraToken.balanceOf(treasuryAddress));
        require(
            veLaraToken.balanceOf(treasuryAddress) == totalVeLaraSupply - rewardTokensAmount,
            "Treasury address balance is not 1M veLARA"
        );

        // give ownership of the staking contract to the treasury address
        stakingContract.transferOwnership(treasuryAddress);

        console.log("Ownership of the staking contract:", stakingContract.owner());

        require(
            stakingContract.owner() == treasuryAddress, "Staking contract ownership is not set to the treasury address"
        );

        // transfer the ownership of the veLARA token to the treasury address
        veLaraToken.transferOwnership(treasuryAddress);

        console.log("Ownership of the veLARA token:", veLaraToken.owner());

        require(veLaraToken.owner() == treasuryAddress, "veLARA token ownership is not set to the treasury address");

        vm.stopBroadcast();
    }
}
