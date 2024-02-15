// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import "../interfaces/IApyOracle.sol";
// import "../Lara.sol";
// import "../ApyOracle.sol";
// import "../mocks/MockDpos.sol";
// import "../stTara.sol";
// import "./SetUpTest.sol";
// import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";

// contract StakersTest is Test, TestSetup {
//     uint256 epochDuration = 0;
//     address[] stakers;

//     function setUp() public {
//         super.setupValidators();
//         super.setupApyOracle();
//         super.setupLara();
//         epochDuration = lara.epochDuration();
//         for (uint256 i = 0; i < 200; i++) {
//             stakers.push(vm.addr(i + 1));
//             vm.deal(stakers[i], 500000 ether);
//         }
//     }

//     function testOneStaker() public {
//         // define value
//         uint256 amount = 500000 ether;

//         lara.stake{value: amount}(amount);

//         // start the epoch
//         lara.startEpoch();

//         vm.roll(epochDuration + lara.lastEpochStartBlock());
//         lara.endEpoch();

//         assertEq(lara.delegatedAmounts(address(this)), amount, "Wrong value");
//     }

//     function testMultipleStakers() public {
//         // define value
//         uint256 amount = 50000 ether;

//         for (uint256 i = 0; i < stakers.length; i++) {
//             vm.prank(stakers[i]);
//             lara.stake{value: amount}(amount);
//             assertEq(
//                 lara.stakedAmounts(stakers[i]),
//                 amount,
//                 "Wrong staked value"
//             );
//         }

//         // start the epoch
//         lara.startEpoch();

//         vm.roll(epochDuration + lara.lastEpochStartBlock());
//         lara.endEpoch();

//         for (uint256 i = 0; i < stakers.length; i++) {
//             assertEq(
//                 lara.delegatedAmounts(stakers[i]),
//                 amount,
//                 "Wrong delegated value"
//             );
//         }
//     }
// }
