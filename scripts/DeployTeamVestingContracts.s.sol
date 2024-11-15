// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployVestingValletsForLaraCoreTeam is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("VESTING_DEPLOYER_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address t1_50M = 0xFA985A9212161e0b515D65711A73f60ba57523a5;
        address t2_25M = 0x7bCAf39fef1018e79ceaBDe60CE4DB995687CCAf;
        address t3_25M = 0x4D3073e691f198A5f4be71268C9619Ded2DFce0f;
        address t4_25M = 0xD42eaA28C5EAfEe9a0040a7aC74dd3f4b57678bD;
        address t5_25M = 0x1e91DB595F4517038bfc7cAcEd911b881Fc4050a;

        uint256 t1ToDisburse = 50_000_000 ether - 2_500_000 ether;

        uint256 othersToDisburse = 25_000_000 ether - 1_250_000 ether;

        /// set up vesting wallet deployment for t1
        VestingWallet v1 = new VestingWallet(t1_50M, 1729525710, 63115200);

        ERC20 laraToken = ERC20(0xE6A69cD4FF127ad8E53C21a593F7BaC4c608945e);
        // send tokens
        laraToken.transfer(address(v1), t1ToDisburse);

        /// set up vesting wallet deployment for t1
        VestingWallet v2 = new VestingWallet(t2_25M, 1729525710, 63115200);

        laraToken.transfer(address(v2), othersToDisburse);

        /// set up vesting wallet deployment for t1
        VestingWallet v3 = new VestingWallet(t3_25M, 1729525710, 63115200);

        laraToken.transfer(address(v3), othersToDisburse);

        /// set up vesting wallet deployment for t1
        VestingWallet v4 = new VestingWallet(t4_25M, 1729525710, 63115200);

        laraToken.transfer(address(v4), othersToDisburse);

        /// set up vesting wallet deployment for t1
        VestingWallet v5 = new VestingWallet(t5_25M, 1729525710, 63115200);

        laraToken.transfer(address(v5), othersToDisburse);

        vm.stopBroadcast();
    }
}
