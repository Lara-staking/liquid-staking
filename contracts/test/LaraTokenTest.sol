// SPDX-License-Identifier: MIT
// Security contact: elod@apeconsulting.xyz
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LaraToken} from "../LaraToken.sol";

contract LaraTokenTest is Test {
    LaraToken laraToken;
    address treasuryAddress;

    function setUp() public {
        treasuryAddress = address(1);
        laraToken = new LaraToken(treasuryAddress);

        assertEq(laraToken.name(), "Lara");
        assertEq(laraToken.symbol(), "LARA");
        assertEq(laraToken.decimals(), 18);
        assertEq(laraToken.totalSupply(), 10000000000 * 1e18);
        assertEq(laraToken.balanceOf(address(this)), laraToken.totalSupply());
        assertEq(laraToken.owner(), address(this));
    }

    function testStartPresale() public {
        assertEq(laraToken.presaleStartBlock(), 0, "presaleStartBlock != 0");
        assertEq(laraToken.presaleRunning(), false, "presaleRunning != false");

        laraToken.transfer(address(laraToken), laraToken.totalSupply() / 10);

        laraToken.startPresale();

        assertEq(laraToken.presaleStartBlock(), 1, "presaleStartBlock != 1");
        assertEq(laraToken.presaleRunning(), true, "presaleRunning != true");
        assertEq(laraToken.presaleEndBlock(), 0, "presaleEndBlock != 0");
    }

    function testPresaleGivesRightAmounts() public {
        testStartPresale();

        assertEq(laraToken.presaleRunning(), true);

        for (uint256 i = 0; i < 15; i++) {
            address presaleAddr = address(vm.addr(i + 1));
            vm.deal(presaleAddr, laraToken.minSwapAmount());
            vm.prank(presaleAddr);
            laraToken.swap{value: presaleAddr.balance}();

            assertEq(
                laraToken.balanceOf(presaleAddr),
                (laraToken.minSwapAmount() * 1724) / 100
            );
        }
    }

    function testFuzz_PresaleRandomAmounts(uint256 amount) public {
        vm.assume(amount <= laraToken.swapUpperLimit());
        testStartPresale();
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

                if (
                    !((amount * 1724) / 100 >
                        laraToken.balanceOf(address(laraToken)))
                ) {
                    uint256 presaleBalance = presaleAddr.balance;
                    vm.prank(presaleAddr);
                    laraToken.swap{value: amount}();

                    assertEq(
                        presaleBalance - presaleAddr.balance,
                        amount,
                        "presaleAddr TARA balance != amount"
                    );
                    assertEq(
                        laraToken.balanceOf(presaleAddr),
                        (amount * 1724) / 100,
                        "amounts do not match"
                    );
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

        vm.roll(
            laraToken.presaleStartBlock() + laraToken.presaleBlockDuration()
        );

        uint256 balanceOfTreasuryBefore = address(treasuryAddress).balance;
        uint256 erc20BalanceOfLaraTokenBefore = laraToken.balanceOf(
            address(laraToken)
        );
        uint256 balanceOfLaraTokenBefore = address(laraToken).balance;

        laraToken.endPresale();

        assertEq(
            laraToken.presaleRunning(),
            false,
            "Presale: presaleRunning != false"
        );

        assertEq(
            laraToken.presaleEndBlock(),
            block.number,
            "Presale: presaleEndBlock != block.number"
        );

        uint256 balanceOfLaraTokenAfter = address(laraToken).balance;

        assertEq(
            balanceOfLaraTokenAfter,
            balanceOfTreasuryBefore,
            "LaraToken still has some $LARA after presale"
        );

        assertEq(
            balanceOfLaraTokenBefore,
            treasuryAddress.balance,
            "Treasury balance != LaraToken balance"
        );

        if (erc20BalanceOfLaraTokenBefore > 0) {
            assertEq(
                laraToken.balanceOf(address(laraToken)),
                0,
                "LaraToken still has some $LARA"
            );

            assertEq(
                laraToken.totalSupply(),
                10000000000 * 1e18 - erc20BalanceOfLaraTokenBefore,
                "LaraToken total supply did not decrease"
            );
        }

        vm.expectRevert("Presale: end already called");
        laraToken.endPresale();
    }
}
