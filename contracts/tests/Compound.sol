// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../interfaces/IApyOracle.sol";
import "../Lara.sol";
import "../ApyOracle.sol";
import "../mocks/MockDpos.sol";
import "../stTara.sol";
import "./SetUp.sol";
import {StakeAmountTooLow, StakeValueTooLow} from "../errors/LaraErrors.sol";

contract LaraTest is Test, TestSetup {
    // set up six random addresses as delegators

    address[] delegators = new address[](6);

    function setupDelegators() private {
        for (uint16 i = 0; i < delegators.length; i++) {
            delegators[i] = vm.addr(i + 13 * i + 13);
            vm.deal(delegators[i], 1000 ether);
            lara.stake{value: 1000 ether}(1000 ether);
        }
    }

    function setUp() public {
        for (uint16 i = 0; i < validators.length; i++) {
            validators[i] = vm.addr(i + 1);
        }
        super.setupValidators();
        super.setupApyOracle();
        super.setupLara();
        setupDelegators();
    }

    function getDelegationTotal(
        address delegator
    ) public view returns (uint256) {
        ILara.IndividualDelegation[] memory delegatorData = lara
            .getIndividualDelegations(delegator);

        uint256 totalDelegated = 0;
        for (uint256 i = 0; i < delegatorData.length; i++) {
            totalDelegated += delegatorData[i].amount;
        }
        return totalDelegated;
    }

    function testFuzz_testCompound(address delegator) public {
        vm.warp(block.timestamp + 1000);
        vm.assume(delegator != address(0));
        // compound the amount
        uint256 stTaraBalanceBfore = stTaraToken.balanceOf(delegator);
        uint256 totalDelegatedBfore = getDelegationTotal(delegator);
        lara.compound(delegator);
        uint256 stTaraBalanceAfter = stTaraToken.balanceOf(delegator);
        uint256 totalDelegatedAfter = getDelegationTotal(delegator);
        if (totalDelegatedBfore == 0) {
            assertTrue(
                totalDelegatedAfter == 0,
                "Delegation amount did not increase"
            );
            assertTrue(
                stTaraBalanceAfter == stTaraBalanceBfore,
                "StTARA balance changed"
            );
        } else {
            assertTrue(
                totalDelegatedAfter > totalDelegatedBfore,
                "Delegation amount did not increase"
            );
            assertTrue(
                stTaraBalanceAfter > stTaraBalanceBfore,
                "StTARA balance did not increase"
            );
        }
        uint256 laraBalace = address(lara).balance;
        assertTrue(laraBalace >= 0, "Lara balance is < zero");
    }

    function invariant_testCompound() public {
        for (uint256 i = 0; i < delegators.length; i++) {
            testFuzz_testCompound(delegators[i]);
        }
    }
}
