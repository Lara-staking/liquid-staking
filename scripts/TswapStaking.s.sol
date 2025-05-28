// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {LaraToken} from "@contracts/LaraToken.sol";
import {veTswap} from "@contracts/veTswap.sol";
import {TswapStaking} from "@contracts/TswapStaking.sol";

contract DeployTswapStaking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_DEPLOYER_KEY");
        address deployerAddress = vm.envAddress("MAINNET_DEPLOYER_ADDR");
        address tswapAddress = vm.envAddress("MAINNET_TSWAP_TOKEN_ADDRESS");
        address treasuryAddress = vm.envAddress("MAINNET_TSWAP_TREASURY_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        veTswap veTswapToken = veTswap(0x58285DdCbC30a8EA37A0b82b8a810E10CCe74D2c);

        uint256 totalVeTswapSupply = 1_000_000_000 ether;

        console.log("veTswap token deployed at address:", address(veTswapToken));

        require(address(veTswapToken.tswap()) == tswapAddress, "Tswap address is not set properly");

        require(
            veTswapToken.balanceOf(deployerAddress) == totalVeTswapSupply, "veTswap balance is not 1000000000 ether"
        );

        // address stakingContractProxy = Upgrades.deployUUPSProxy(
        //     "TswapStaking.sol",
        //     abi.encodeCall(
        //         TswapStaking.initialize,
        //         (
        //             address(veTswapToken),
        //             address(tswapAddress),
        //             1,
        //             1, // equals to 1% APY
        //             3155760000,
        //             426445 // 6 months
        //         )
        //     )
        // );

        TswapStaking stakingContract = TswapStaking(payable(0x77aC84aC3C0c2aeA674B9fe41c5363D7A0ec9dE4));

        console.log("Staking contract deployed at address:", address(stakingContract));

        // address stakingImplementation = Upgrades.getImplementationAddress(address(stakingContractProxy));

        // console.log("Staking implementation deployed at address:", stakingImplementation);

        uint256 rewardTokensAmount = 1_000_000 ether;
        // add 1M TSWAP to the staking contract
        veTswapToken.approve(address(stakingContract), rewardTokensAmount);
        stakingContract.depositRewardTokens(rewardTokensAmount);

        console.log("Deposited 1M veTSWAP to the staking contract");

        require(
            veTswapToken.balanceOf(address(stakingContract)) == rewardTokensAmount,
            "Staking contract balance is not 1M veTSWAP"
        );

        // send the rest of the veTSWAP to the treasury address
        veTswapToken.transfer(treasuryAddress, veTswapToken.balanceOf(address(deployerAddress)));

        console.log("Sent the rest of the veTSWAP to the treasury address");

        // verify the balance of the treasury address
        console.log("Treasury address balance:", veTswapToken.balanceOf(treasuryAddress));
        require(
            veTswapToken.balanceOf(treasuryAddress) == totalVeTswapSupply - rewardTokensAmount,
            "Treasury address balance is not 1M veTSWAP"
        );

        // give ownership of the staking contract to the treasury address
        stakingContract.transferOwnership(treasuryAddress);

        console.log("Ownership of the staking contract:", stakingContract.owner());

        require(
            stakingContract.owner() == treasuryAddress, "Staking contract ownership is not set to the treasury address"
        );

        // transfer the ownership of the veTSWAP token to the treasury address
        veTswapToken.transferOwnership(treasuryAddress);

        console.log("Ownership of the veTSWAP token:", veTswapToken.owner());

        require(veTswapToken.owner() == treasuryAddress, "veTSWAP token ownership is not set to the treasury address");

        vm.stopBroadcast();
    }
}
