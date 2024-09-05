// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LaraToken} from "../LaraToken.sol";

contract LaraTokenPresaleTest is Test {
    LaraToken laraToken;
    address treasuryAddress;

    uint8 presaleRate = 4;

    function setUp() public {
        treasuryAddress = address(1);
        laraToken = new LaraToken(treasuryAddress);

        assertEq(laraToken.name(), "Lara");
        assertEq(laraToken.symbol(), "LARA");
        assertEq(laraToken.decimals(), 18);
        assertEq(laraToken.totalSupply(), 1000000000 ether);
        assertEq(laraToken.presaleRate(), 4);
        assertEq(laraToken.swapUpperLimit(), 1000000 ether);
        assertEq(laraToken.minSwapAmount(), 1000 ether);
        assertEq(laraToken.swapPeriod(), 900);
        assertEq(laraToken.treasuryAddress(), treasuryAddress);
        assertEq(laraToken.balanceOf(address(this)), laraToken.totalSupply());
        assertEq(laraToken.presaleEndBlock(), 0);

        assertEq(laraToken.presaleStartBlock(), 0, "presaleStartBlock != 0");
        assertEq(laraToken.presaleRunning(), false, "presaleRunning != false");

        laraToken.transfer(address(laraToken), laraToken.totalSupply() / 10);

        laraToken.startPresale();

        assertEq(laraToken.presaleStartBlock(), 1, "presaleStartBlock != 1");
        assertEq(laraToken.presaleRunning(), true, "presaleRunning != true");
        assertEq(laraToken.presaleEndBlock(), 0, "presaleEndBlock != 0");
    }

    function testPresaleGivesRightAmounts() public {
        assertEq(laraToken.presaleRunning(), true);

        for (uint256 i = 0; i < 15; i++) {
            address presaleAddr = address(vm.addr(i + 1));
            vm.deal(presaleAddr, laraToken.minSwapAmount());
            vm.prank(presaleAddr);
            laraToken.swap{value: presaleAddr.balance}();

            assertEq(laraToken.balanceOf(presaleAddr), (laraToken.minSwapAmount() * presaleRate));
        }

        for (uint256 i = 0; i < 15; i++) {
            address presaleAddr = address(vm.addr(i + 1));
            vm.deal(presaleAddr, laraToken.swapUpperLimit());
            vm.prank(presaleAddr);
            laraToken.swap{value: presaleAddr.balance}();

            assertEq(
                laraToken.balanceOf(presaleAddr),
                ((laraToken.swapUpperLimit() * presaleRate) + (laraToken.minSwapAmount() * presaleRate))
            );
        }
    }

    function test_successiveSwaps_Lockout() public {
        vm.roll(1);
        address swapper = vm.addr(666);
        vm.deal(swapper, 1200000 ether);
        uint256 laraTokenBalanceBefore = laraToken.balanceOf(address(laraToken));
        // first the swapper swaps for 300000 ETH
        vm.prank(swapper);
        laraToken.swap{value: 300000 ether}();

        assertEq(
            laraToken.balanceOf(swapper), 300000 ether * presaleRate, "swapper balance != 300000 ether * presaleRate"
        );
        assertEq(laraToken.lastSwapBlock(swapper), 0, "lastSwapBlock != 0");
        assertEq(
            laraToken.balanceOf(address(laraToken)),
            laraTokenBalanceBefore - 300000 ether * presaleRate,
            "LaraToken balance != laraTokenBalanceBefore - 300000 ether * presaleRate"
        );
        // then the swapper swaps for 1000000 ETH
        uint256 laraTokenBalanceAfterFirstSwap = laraToken.balanceOf(address(laraToken));
        vm.roll(block.number + 1);
        vm.prank(swapper);
        laraToken.swap{value: 700000 ether}();
        uint256 laraTokenBalanceAfterSecondSwap = laraToken.balanceOf(address(laraToken));
        //now, the swapper has more than presaleRate * swapUpperLimit and should be waitlisted for 900 blocks
        assertEq(laraToken.balanceOf(swapper), 1000000 ether * 4, "swapper balance != 1000000 ether * presaleRate");
        assertEq(laraToken.lastSwapBlock(swapper), block.number, "lastSwapBlock != block.number");
        uint256 expectedLaraTokenBalanceAfterSecondSwap = laraTokenBalanceAfterFirstSwap - 2800000 ether;
        assertEq(
            laraToken.balanceOf(address(laraToken)),
            expectedLaraTokenBalanceAfterSecondSwap,
            "LaraToken balance != expectedLaraTokenBalanceAfterSecondSwap"
        );
        assertEq(address(laraToken).balance, 1000000 ether, "LaraToken balance != 1000000 ether");

        //swapper tries to swap again but get reverted because he needs to wait
        vm.expectRevert("Presale: you can swap once every 900 blocks");
        vm.prank(swapper);
        laraToken.swap{value: 100000 ether}();

        // now, the swapper can swap again at block 902
        vm.roll(block.number + 900);
        vm.prank(swapper);
        laraToken.swap{value: 100000 ether}();
        assertEq(laraToken.lastSwapBlock(swapper), 902, "lastSwapBlock != 902");
        assertEq(laraToken.balanceOf(swapper), 1100000 ether * 4, "swapper balance != 1100000 ether * presaleRate");
        assertEq(
            laraToken.balanceOf(address(laraToken)),
            laraTokenBalanceAfterSecondSwap - (100000 ether * 4),
            "LaraToken balance != laraTokenBalanceAfterSecondSwap - (100000 ether * presaleRate)"
        );
        assertEq(address(laraToken).balance, 1100000 ether, "LaraToken balance != 1100000 ether");
    }

    function test_presaleRunning_allTokensClaimed_swapsFail() public {
        vm.roll(block.number + 1);
        uint16 numOfAddresses = 125;
        for (uint16 i = 100; i < numOfAddresses; i++) {
            address presaleAddr = vm.addr(i + 1);
            assertEq(laraToken.balanceOf(presaleAddr), 0, "presaleAddr balance != 0");
            vm.deal(presaleAddr, laraToken.swapUpperLimit() + 1 ether);
            vm.startPrank(presaleAddr);
            laraToken.swap{value: laraToken.swapUpperLimit()}();
            assertEq(
                laraToken.balanceOf(presaleAddr),
                (laraToken.swapUpperLimit() * presaleRate),
                "presaleAddr balance != (laraToken.swapUpperLimit() * presaleRate)"
            );
            vm.stopPrank();
        }

        assertEq(laraToken.balanceOf(address(laraToken)), 0, "LaraToken balance != 0");
        vm.roll(block.number + laraToken.presaleBlockDuration());
        laraToken.endPresale();
    }

    function testFuzz_PresaleRandomAmounts(uint256 amount) public {
        vm.assume(amount <= laraToken.swapUpperLimit());
        address presaleAddr = address(vm.addr(777));
        vm.deal(presaleAddr, amount);
        if (amount > laraToken.totalSupply() / 10) {
            vm.expectRevert();
            vm.prank(presaleAddr);
            laraToken.swap{value: presaleAddr.balance}();
        } else {
            if (amount < laraToken.minSwapAmount()) {
                vm.expectRevert("Presale: amount too low");
                vm.prank(presaleAddr);
                laraToken.swap{value: presaleAddr.balance}();
            } else {
                assertEq(laraToken.presaleRunning(), true);

                if (!((amount * presaleRate) / 100 > laraToken.balanceOf(address(laraToken)))) {
                    uint256 presaleBalance = presaleAddr.balance;
                    vm.prank(presaleAddr);
                    laraToken.swap{value: amount}();

                    assertEq(presaleBalance - presaleAddr.balance, amount, "presaleAddr TARA balance != amount");
                    assertEq(laraToken.balanceOf(presaleAddr), amount * presaleRate, "amounts do not match");
                }
            }
        }
    }

    function testEndPresale_failsOnBlockFirstTheSucceeds() public {
        testPresaleGivesRightAmounts();

        uint256 balanceOfLaraToken = laraToken.balanceOf(address(laraToken));
        assertTrue(balanceOfLaraToken > 0, "LaraToken still has some $LARA");

        vm.expectRevert("Presale: presale not ended");
        laraToken.endPresale();

        vm.roll(laraToken.presaleStartBlock() + laraToken.presaleBlockDuration());

        uint256 balanceOfTreasuryBefore = address(treasuryAddress).balance;
        uint256 erc20BalanceOfLaraTokenBefore = laraToken.balanceOf(address(laraToken));
        uint256 balanceOfLaraTokenBefore = address(laraToken).balance;

        laraToken.endPresale();

        assertEq(laraToken.presaleRunning(), false, "Presale: presaleRunning != false");

        assertEq(laraToken.presaleEndBlock(), block.number, "Presale: presaleEndBlock != block.number");

        uint256 balanceOfLaraTokenAfter = address(laraToken).balance;

        assertEq(balanceOfLaraTokenAfter, balanceOfTreasuryBefore, "LaraToken still has some $LARA after presale");

        assertEq(balanceOfLaraTokenBefore, treasuryAddress.balance, "Treasury balance != LaraToken balance");

        if (erc20BalanceOfLaraTokenBefore > 0) {
            assertEq(laraToken.balanceOf(address(laraToken)), 0, "LaraToken still has some $LARA");

            assertEq(
                laraToken.totalSupply(),
                1000000000 ether - erc20BalanceOfLaraTokenBefore,
                "LaraToken total supply did not decrease"
            );
        }

        vm.expectRevert("Presale: end already called");
        laraToken.endPresale();
    }
}
