// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {LaraToken} from "@contracts/LaraToken.sol";

contract LaraTokenBaseTest is Test {
    LaraToken public laraToken;
    address public treasury;
    address public user1;
    address public user2;

    function setUp() public {
        treasury = makeAddr("treasury");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(treasury);
        laraToken = new LaraToken(treasury);
        laraToken.transfer(address(laraToken), laraToken.totalSupply() / 10);
        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(laraToken.name(), "Lara");
        assertEq(laraToken.symbol(), "LARA");
        assertEq(laraToken.decimals(), 18);
        assertEq(laraToken.totalSupply(), 1000000000 ether);
        assertEq(laraToken.balanceOf(treasury), 900000000 ether);
        assertEq(laraToken.balanceOf(address(laraToken)), 100000000 ether);
        assertEq(laraToken.treasuryAddress(), treasury);
        assertEq(laraToken.minSwapAmount(), 1000 ether);
        assertEq(laraToken.presaleBlockDuration(), 151200);
        assertEq(laraToken.swapUpperLimit(), 1000000 ether);
        assertEq(laraToken.presaleRate(), 4);
        assertEq(laraToken.swapPeriod(), 900);
        assertFalse(laraToken.presaleRunning());
    }

    function test_StartPresale() public {
        vm.prank(treasury);
        laraToken.startPresale();

        assertTrue(laraToken.presaleRunning());
        assertEq(laraToken.presaleStartBlock(), block.number);
    }

    function test_CannotStartPresaleTwice() public {
        vm.startPrank(treasury);
        laraToken.startPresale();
        vm.expectRevert("Presale: start already called");
        laraToken.startPresale();
        vm.stopPrank();
    }

    function test_EndPresale() public {
        vm.prank(treasury);
        laraToken.startPresale();

        vm.roll(block.number + laraToken.presaleBlockDuration() + 1);

        uint256 initialTreasuryBalance = treasury.balance;
        vm.prank(treasury);
        laraToken.endPresale();

        assertFalse(laraToken.presaleRunning());
        assertEq(laraToken.presaleEndBlock(), block.number);
        assertEq(laraToken.balanceOf(address(laraToken)), 0);
        assertEq(treasury.balance, initialTreasuryBalance);
    }

    function test_CannotEndPresaleBeforeDuration() public {
        vm.prank(treasury);
        laraToken.startPresale();

        vm.roll(block.number + laraToken.presaleBlockDuration() - 1);

        vm.expectRevert("Presale: presale not ended");
        vm.prank(treasury);
        laraToken.endPresale();
    }

    function test_Swap() public {
        vm.prank(treasury);
        laraToken.startPresale();

        uint256 swapAmount = 1000 ether;
        vm.deal(user1, swapAmount);

        vm.prank(user1);
        laraToken.swap{value: swapAmount}();

        assertEq(laraToken.balanceOf(user1), swapAmount * laraToken.presaleRate());
        assertEq(address(laraToken).balance, swapAmount);
    }

    function test_CannotSwapBelowMinimum() public {
        vm.prank(treasury);
        laraToken.startPresale();

        uint256 swapAmount = 999 ether;
        vm.deal(user1, swapAmount);

        vm.expectRevert("Presale: amount too low");
        vm.prank(user1);
        laraToken.swap{value: swapAmount}();
    }

    function test_CannotSwapAboveUpperLimit() public {
        vm.prank(treasury);
        laraToken.startPresale();

        uint256 swapAmount = 1000001 ether;
        vm.deal(user1, swapAmount);

        vm.expectRevert("Presale: you can swap max 1000000 TARA");
        vm.prank(user1);
        laraToken.swap{value: swapAmount}();
    }

    function test_SwapCooldown() public {
        vm.prank(treasury);
        laraToken.startPresale();

        uint256 swapAmount = 1000000 ether;
        vm.deal(user1, swapAmount * 2);

        vm.startPrank(user1);
        laraToken.swap{value: swapAmount}();

        vm.expectRevert("Presale: you can swap once every 900 blocks");
        laraToken.swap{value: swapAmount}();

        vm.roll(block.number + laraToken.swapPeriod());
        laraToken.swap{value: swapAmount}();
        vm.stopPrank();

        assertEq(laraToken.balanceOf(user1), swapAmount * laraToken.presaleRate() * 2);
    }

    function test_CannotSwapWhenPresaleNotRunning() public {
        uint256 swapAmount = 1000 ether;
        vm.deal(user1, swapAmount);

        vm.expectRevert("Presale: presale not running");
        vm.prank(user1);
        laraToken.swap{value: swapAmount}();
    }
}
