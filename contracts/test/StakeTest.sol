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
        assertEq(
            mockDpos.getTotalDelegation(address(lara)),
            amount,
            "Wrong staked amount after stake"
        );
        assertEq(
            stTaraToken.balanceOf(address(this)),
            amount,
            "Wrong stTARA balance after stake"
        );

        // Check if the validators array size increased by 1
        uint256 delegations;
        if (amount % 80000000 ether == 0) {
            delegations = amount / 80000000 ether;
        } else {
            delegations = amount / 80000000 ether + 1;
        }
        for (uint8 i = 0; i < delegations; i++) {
            assertEq(
                lara.validators(i),
                validators[i],
                "Validator not registered"
            );
        }

        stTaraToken.approve(address(lara), amount);
        // Call the unstake function
        uint256 balanceBeforeUndelegate = address(this).balance;
        Utils.Undelegation[] memory undelegations = lara.requestUndelegate(
            amount
        );
        uint256 balanceAfterUndelegate = address(this).balance;
        assertEq(
            stTaraToken.balanceOf(address(this)),
            0,
            "Wrong stTARA balance after requestUndelegate"
        );

        assertEq(
            balanceAfterUndelegate - balanceBeforeUndelegate,
            333 ether * undelegations.length,
            "Wrong rewards given after requestUndelegate"
        );
        assertEq(
            lara.undelegated(address(this)),
            amount,
            "Wrong undelegated amount in lara"
        );

        uint256 initialUndelegated = lara.undelegated(address(this));
        vm.roll(mockDpos.UNDELEGATION_DELAY_BLOCKS() + block.number);
        for (uint256 i = 0; i < undelegations.length; i++) {
            uint256 balanceBefore = address(this).balance;
            lara.confirmUndelegate(
                undelegations[i].validator,
                undelegations[i].amount
            );
            uint256 balanceAfter = address(this).balance;
            assertEq(
                lara.undelegated(address(this)),
                initialUndelegated - undelegations[i].amount,
                "Wrong undelegated"
            );
            assertEq(
                balanceAfter - balanceBefore,
                undelegations[i].amount,
                "Wrong delegation given"
            );
            initialUndelegated = lara.undelegated(address(this));
        }
    }

    function stakeAndCancelUnstake(uint256 amount) public {
        // Call the stake function
        uint256 remaining = lara.stake{value: amount}(amount);

        amount -= remaining;
        // Check the staked amount
        assertEq(
            mockDpos.getTotalDelegation(address(lara)),
            amount,
            "Wrong staked amount after stake"
        );
        assertEq(
            stTaraToken.balanceOf(address(this)),
            amount,
            "Wrong stTARA balance after stake"
        );

        // Check if the validators array size increased by 1
        uint256 delegations;
        if (amount % 80000000 ether == 0) {
            delegations = amount / 80000000 ether;
        } else {
            delegations = amount / 80000000 ether + 1;
        }
        for (uint8 i = 0; i < delegations; i++) {
            assertEq(
                lara.validators(i),
                validators[i],
                "Validator not registered"
            );
        }

        stTaraToken.approve(address(lara), amount);
        // Call the unstake function
        uint256 balanceBeforeUndelegate = address(this).balance;
        Utils.Undelegation[] memory undelegations = lara.requestUndelegate(
            amount
        );
        uint256 balanceAfterUndelegate = address(this).balance;
        assertEq(
            stTaraToken.balanceOf(address(this)),
            0,
            "Wrong stTARA balance after requestUndelegate"
        );

        assertEq(
            balanceAfterUndelegate - balanceBeforeUndelegate,
            333 ether * undelegations.length,
            "Wrong rewards given after requestUndelegate"
        );
        assertEq(
            lara.undelegated(address(this)),
            amount,
            "Wrong undelegated amount in lara"
        );

        uint256 initialUndelegated = lara.undelegated(address(this));
        vm.roll(mockDpos.UNDELEGATION_DELAY_BLOCKS() + block.number);
        for (uint256 i = 0; i < undelegations.length; i++) {
            uint256 stTaraBalanceBefore = stTaraToken.balanceOf(address(this));
            lara.cancelUndelegate(
                undelegations[i].validator,
                undelegations[i].amount
            );
            uint256 stTaraBalanceAfter = stTaraToken.balanceOf(address(this));
            assertEq(
                lara.undelegated(address(this)),
                initialUndelegated - undelegations[i].amount,
                "Wrong undelegated"
            );
            assertEq(
                stTaraBalanceAfter - stTaraBalanceBefore,
                undelegations[i].amount,
                "Wrong stTARA amount minted"
            );
            initialUndelegated = lara.undelegated(address(this));
        }
    }

    function testStakeAndUnstake() public {
        uint256 amount = 500000 ether;

        stakeAndUnstake(amount);
    }

    function testFailStakeAmountTooLow() public {
        // Call the function with an amount less than the minimum stake amount
        vm.expectRevert(StakeAmountTooLow.selector);
        lara.stake{value: 500 ether}(500 ether);
    }

    function testFailStakeValueTooLow() public {
        // Call the function with a value less than the staking amount
        vm.expectRevert(StakeValueTooLow.selector);
        lara.stake{value: 400000 ether}(500000 ether);
    }

    function testFailUnstakeAmountNotApproved() public {
        // Call the function with an amount greater than the staked amount
        vm.expectRevert("revert: Amount not approved for unstaking");
        lara.requestUndelegate(6000000 ether);
    }

    function testNotRegisteredTwice() public {
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

    function testFuzz_unstakeMoreThanStaked(uint256 amount) public {
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
        assertTrue(
            lara.totalDelegated() == stTaraToken.totalSupply(),
            "Total delegated not equal to total supply"
        );
        stakeAndCancelUnstake(100000 ether);
        assertTrue(
            lara.totalDelegated() == stTaraToken.totalSupply(),
            "Total delegated not equal to total supply"
        );
    }
}
