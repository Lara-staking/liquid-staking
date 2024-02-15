// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";
import {Utils} from "../libs/Utils.sol";

contract UnstakeTest is Test, TestSetup {
    uint256 epochDuration = 0;
    uint256 stakes = 10;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLaraFactoryWithCommission(3);
        super.createLara();
        epochDuration = lara.epochDuration();
    }

    function multipleStakes(uint256 amount) public {
        for (uint256 i = 0; i < stakes; i++) {
            address staker = vm.addr(i + 1);
            vm.deal(staker, amount / 10);
            vm.prank(staker);
            address payable laraAddress = laraFactory.createLara();
            lara = Lara(laraAddress);
            lara.stake{value: amount / 10}(amount / 10);

            assertEq(
                stTaraToken.balanceOf(staker),
                amount / 10,
                "Wrong stTARA balance after stake"
            );
        }
    }

    function multipleFullUnstakes() public {
        for (uint256 i = 0; i < stakes; i++) {
            address staker = vm.addr(i + 1);
            vm.startPrank(staker);
            stTaraToken.approve(address(lara), stTaraToken.balanceOf(staker));
            address laraInstanceOfStaker = laraFactory.laraInstances(
                address(staker)
            );
            Lara laraOfStaker = Lara(payable(laraInstanceOfStaker));
            address[] memory validatorsOfDelegator = laraOfStaker
                .getValidators();
            for (uint256 j = 0; j < validatorsOfDelegator.length; j++) {
                uint256 stTaraBalanceBefore = stTaraToken.balanceOf(staker);
                uint256 totalStakeAtValidator = laraOfStaker
                    .totalStakeAtValidator(validatorsOfDelegator[j]);
                laraOfStaker.requestUndelegate(
                    validatorsOfDelegator[j],
                    totalStakeAtValidator
                );
                assertEq(
                    laraOfStaker.totalStakeAtValidator(
                        validatorsOfDelegator[j]
                    ),
                    0,
                    "Wrong staked amount at validator"
                );
                assertEq(
                    stTaraToken.balanceOf(staker),
                    stTaraBalanceBefore - totalStakeAtValidator,
                    "Wrong stTARA balance after requestUndelegate"
                );
            }
            assertEq(
                stTaraToken.balanceOf(staker),
                0,
                "Wrong stTARA balance after requestUndelegate"
            );
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
