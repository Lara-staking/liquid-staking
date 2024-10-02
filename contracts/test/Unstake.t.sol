// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "@contracts/interfaces/IApyOracle.sol";
import {Lara} from "@contracts/Lara.sol";
import {ApyOracle} from "@contracts/ApyOracle.sol";
import {MockDpos} from "@contracts/mocks/MockDpos.sol";
import {StakedNativeAsset} from "@contracts/StakedNativeAsset.sol";
import {TestSetup} from "@contracts/test/SetUp.t.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "@contracts/libs/SharedErrors.sol";

contract UnstakeTest is Test, TestSetup {
    uint256 epochDuration = 0;
    uint256 stakes = 10;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
    }

    function multipleStakes(uint256 amount) public {
        for (uint256 i = 0; i < stakes; i++) {
            address staker = vm.addr(i + 1);
            vm.deal(staker, amount / 10);
            vm.prank(staker);
            lara.stake{value: amount / 10}(amount / 10);

            assertEq(stTaraToken.balanceOf(staker), amount / 10, "Wrong stTARA balance after stake");
        }
    }

    function multipleFullUnstakes() public {
        for (uint256 i = 0; i < stakes; i++) {
            address staker = vm.addr(i + 1);
            vm.startPrank(staker);
            stTaraToken.approve(address(lara), stTaraToken.balanceOf(staker));

            uint64[] memory undelegationIds = lara.requestUndelegate(stTaraToken.balanceOf(staker));
            assertTrue(undelegationIds.length >= 1, "No undelegations");
            assertEq(stTaraToken.balanceOf(staker), 0, "Wrong stTARA balance after requestUndelegate");
            vm.stopPrank();
        }
    }

    function testFuzz_stakeAndFullyUnstake(uint256 amount) public {
        vm.assume(amount > lara.minStakeAmount() * 10);
        vm.assume(amount < 960000000 ether);
        // Call the stake function
        multipleStakes(amount);

        multipleFullUnstakes();
    }
}
