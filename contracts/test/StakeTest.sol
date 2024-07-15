// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IApyOracle} from "../interfaces/IApyOracle.sol";
import {Lara} from "../Lara.sol";
import {ApyOracle} from "../ApyOracle.sol";
import {MockDpos} from "../mocks/MockDpos.sol";
import {StakedTara} from "../StakedTara.sol";
import {TestSetup} from "./SetUpTest.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../libs/SharedErrors.sol";
import {Utils} from "../libs/Utils.sol";

contract StakeTest is Test, TestSetup {
    uint256 epochDuration = 0;

    function setUp() public {
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        epochDuration = lara.epochDuration();
    }

    function stakeAndUnstake(uint256 amount) public {
        // Call the stake function
        uint256 remaining = lara.stake{value: amount}(amount);

        amount -= remaining;
        // Check the staked amount
        assertEq(mockDpos.getTotalDelegation(address(lara)), amount, "Wrong staked amount after stake");
        assertEq(stTaraToken.balanceOf(address(this)), amount, "Wrong stTARA balance after stake");

        // Check if the validators array size increased by 1
        uint256 delegations;
        if (amount % 80000000 ether == 0) {
            delegations = amount / 80000000 ether;
        } else {
            delegations = amount / 80000000 ether + 1;
        }
        for (uint8 i = 0; i < delegations; i++) {
            assertEq(lara.validators(i), validators[i], "Validator not registered");
        }

        stTaraToken.approve(address(lara), amount);
        // Call the unstake function
        uint256 balanceBeforeUndelegate = address(this).balance;
        uint64[] memory undelegationIds = lara.requestUndelegate(amount);
        uint256 balanceAfterUndelegate = address(this).balance;
        assertEq(stTaraToken.balanceOf(address(this)), 0, "Wrong stTARA balance after requestUndelegate");

        assertEq(
            balanceAfterUndelegate - balanceBeforeUndelegate,
            333 ether * undelegationIds.length,
            "Wrong rewards given after requestUndelegate"
        );
        assertEq(lara.undelegated(address(this)), amount, "Wrong undelegated amount in lara");

        uint256 initialUndelegated = lara.undelegated(address(this));
        vm.roll(mockDpos.UNDELEGATION_DELAY_BLOCKS() + block.number);
        for (uint256 i = 0; i < undelegationIds.length; i++) {
            uint256 balanceBefore = address(this).balance;
            lara.confirmUndelegate(undelegationIds[i]);
            uint256 balanceAfter = address(this).balance;
            initialUndelegated = lara.undelegated(address(this));
        }
    }

    function stakeAndCancelUnstake(uint256 amount) public {
        // Call the stake function
        uint256 remaining = lara.stake{value: amount}(amount);

        amount -= remaining;
        // Check the staked amount
        assertEq(mockDpos.getTotalDelegation(address(lara)), amount, "Wrong staked amount after stake");
        assertEq(stTaraToken.balanceOf(address(this)), amount, "Wrong stTARA balance after stake");

        // Check if the validators array size increased by 1
        uint256 delegations;
        if (amount % 80000000 ether == 0) {
            delegations = amount / 80000000 ether;
        } else {
            delegations = amount / 80000000 ether + 1;
        }
        for (uint8 i = 0; i < delegations; i++) {
            assertEq(lara.validators(i), validators[i], "Validator not registered");
        }

        stTaraToken.approve(address(lara), amount);
        // Call the unstake function
        uint256 balanceBeforeUndelegate = address(this).balance;
        uint64[] memory undelegationIds = lara.requestUndelegate(amount);
        uint256 balanceAfterUndelegate = address(this).balance;
        assertEq(stTaraToken.balanceOf(address(this)), 0, "Wrong stTARA balance after requestUndelegate");

        assertEq(
            balanceAfterUndelegate - balanceBeforeUndelegate,
            333 ether * undelegationIds.length,
            "Wrong rewards given after requestUndelegate"
        );
        assertEq(lara.undelegated(address(this)), amount, "Wrong undelegated amount in lara");

        uint256 initialUndelegated = lara.undelegated(address(this));
        vm.roll(mockDpos.UNDELEGATION_DELAY_BLOCKS() + block.number);
        for (uint256 i = 0; i < undelegationIds.length; i++) {
            uint256 stTaraBalanceBefore = stTaraToken.balanceOf(address(this));
            lara.cancelUndelegate(undelegationIds[i]);
            uint256 stTaraBalanceAfter = stTaraToken.balanceOf(address(this));
            initialUndelegated = lara.undelegated(address(this));
        }
    }

    function test_StakeAndUnstake() public {
        uint256 amount = 500000 ether;

        stakeAndUnstake(amount);
    }

    function test_Revert_On_StakeAmountTooLow() public {
        // Call the function with an amount less than the minimum stake amount
        vm.expectRevert(abi.encodeWithSelector(StakeAmountTooLow.selector, 500 ether, lara.minStakeAmount()));
        lara.stake{value: 500 ether}(500 ether);
    }

    function tes_Revert_On_StakeValueTooLow() public {
        // Call the function with a value less than the staking amount
        vm.expectRevert(StakeValueTooLow.selector);
        lara.stake{value: 400000 ether}(500000 ether);
    }

    function test_Revert_On_UnstakeAmountNotApproved() public {
        // Call the function with an amount greater than the staked amount
        vm.expectRevert("Amount not approved for unstaking");
        lara.requestUndelegate(6000000 ether);
    }

    function test_Revert_On_Double_Register() public {
        uint256 amount = 500000 ether;

        // Call the stake function
        lara.stake{value: amount}(amount);

        assertEq(lara.delegators(0), address(this));

        vm.expectRevert();
        assertEq(lara.delegators(1), address(0));

        lara.stake{value: amount}(amount);

        assertEq(lara.delegators(0), address(this));

        vm.expectRevert();
        assertEq(lara.delegators(1), address(0));
    }

    function testFuzz_stakeAndUnstake(uint256 amount) public {
        vm.assume(amount > lara.minStakeAmount());
        vm.assume(amount < 10000000000 ether);
        vm.deal(address(this), amount);
        stakeAndUnstake(amount);
    }

    function testFuzz_Revert_On_unstakeMoreThanStaked(uint256 amount) public {
        vm.assume(amount > lara.minStakeAmount());
        vm.assume(amount < 100000000000 ether);
        vm.deal(address(this), amount);
        lara.stake{value: amount}(amount);
        stTaraToken.approve(address(lara), amount + 1);
        vm.expectRevert();
        lara.requestUndelegate(amount + 1);
    }

    function test_stakeAndCancelUndelegate() public {
        uint256 amount = 500000 ether;
        stakeAndCancelUnstake(amount);
    }

    function testFuzz_stakeAndCancelUndelegate(uint256 amount) public {
        vm.assume(amount > lara.minStakeAmount());
        vm.assume(amount < 10000000000 ether);
        vm.deal(address(this), amount);
        stakeAndCancelUnstake(amount);
    }

    function invariant_stakeAndCancelUndelegate() public {
        assertTrue(lara.totalDelegated() == stTaraToken.totalSupply(), "Total delegated not equal to total supply");
        stakeAndCancelUnstake(100000 ether);
        assertTrue(lara.totalDelegated() == stTaraToken.totalSupply(), "Total delegated not equal to total supply");
    }
}
