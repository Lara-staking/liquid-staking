// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@contracts/veLara.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Lara", "MLARA") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract veLaraTest is Test {
    veLara public veLaraContract;
    MockERC20 public laraToken;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x123);
        laraToken = new MockERC20();
        veLaraContract = new veLara(address(laraToken));

        // Mint some tokens to the user for testing
        laraToken.mint(user, 1000 * 10 ** 18);
    }

    function test_Deposit() public {
        uint256 depositAmount = 100 * 10 ** 18;

        // Approve veLara contract to spend user's tokens
        vm.prank(user);
        laraToken.approve(address(veLaraContract), depositAmount);

        // Check initial balances
        assertEq(laraToken.balanceOf(user), 1000 * 10 ** 18);
        assertEq(laraToken.balanceOf(address(veLaraContract)), 0);
        assertEq(veLaraContract.balanceOf(user), 0);

        // Deposit tokens
        vm.prank(user);
        veLaraContract.deposit(depositAmount);

        // Check balances after deposit
        assertEq(laraToken.balanceOf(user), 900 * 10 ** 18);
        assertEq(laraToken.balanceOf(address(veLaraContract)), depositAmount);
        assertEq(veLaraContract.balanceOf(user), depositAmount);
    }

    function testFail_DepositWithoutApproval() public {
        uint256 depositAmount = 100 * 10 ** 18;

        // Attempt to deposit without approval
        vm.prank(user);
        veLaraContract.deposit(depositAmount);
    }
}
