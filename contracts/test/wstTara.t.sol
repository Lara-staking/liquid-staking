// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@contracts/wstTARA.sol";
import "@contracts/StakedNativeAsset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract WrappedStTaraTestSuite is Test {
    WrappedStTara wrappedStTara;
    StakedNativeAsset stakedNativeAsset;
    IERC20 stakingToken;
    address user = address(0x123);
    address treasury = address(0x789);

    uint256 STAKED_AMOUNT = 10 ether;
    uint256 TOTAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        stakingToken = new StakedNativeAsset();
        stakedNativeAsset = StakedNativeAsset(address(stakingToken));
        stakedNativeAsset.setLaraAddress(address(this));
        wrappedStTara = new WrappedStTara(address(stakedNativeAsset));

        // Mint some staked tokens to the user
        stakedNativeAsset.mint(user, TOTAL_SUPPLY);
        assertEq(stakedNativeAsset.balanceOf(user), TOTAL_SUPPLY, "User should have 1000 stTARA");
    }

    // Test wrapping stTARA tokens
    function test_WrapStTara() public {
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        assertEq(wrappedStTara.balanceOf(user), STAKED_AMOUNT, "User should have wrapped stTARA tokens");
        vm.stopPrank();
    }

    // Test unwrapping wstTARA tokens
    function test_UnwrapWstTara() public {
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        wrappedStTara.withdraw(STAKED_AMOUNT, user, user);
        assertEq(wrappedStTara.balanceOf(user), 0, "User should have no wrapped stTARA tokens");
        assertEq(stakedNativeAsset.balanceOf(user), TOTAL_SUPPLY, "User should have original stTARA tokens back");
        vm.stopPrank();
    }

    // Test wrapping without approval
    function test_WrapWithoutApproval() public {
        vm.startPrank(user);
        vm.expectRevert();
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        vm.stopPrank();
    }

    // Test unwrapping without wrapped tokens
    function test_UnwrapWithoutWrappedTokens() public {
        vm.startPrank(user);
        vm.expectRevert();
        wrappedStTara.withdraw(STAKED_AMOUNT, user, user);
        vm.stopPrank();
    }

    // Test wrapping and unwrapping multiple times
    function test_WrapAndUnwrapMultipleTimes() public {
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT * 2);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        wrappedStTara.withdraw(STAKED_AMOUNT, user, user);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        wrappedStTara.withdraw(STAKED_AMOUNT, user, user);
        assertEq(wrappedStTara.balanceOf(user), 0, "User should have no wrapped stTARA tokens");
        assertEq(stakedNativeAsset.balanceOf(user), TOTAL_SUPPLY, "User should have original stTARA tokens back");
        vm.stopPrank();
    }

    function test_Wrap_Rebase_And_Unwrap() public {
        // Mint 1000 stTARA to the treasury

        uint256 totalStakedNativeAssetSupplyInitial = stakedNativeAsset.totalSupply();

        stakedNativeAsset.mint(treasury, 1000 ether);

        // Wrap 1000 stTARA
        vm.startPrank(treasury);
        stakedNativeAsset.approve(address(wrappedStTara), 1000 ether);
        wrappedStTara.deposit(1000 ether, treasury);
        vm.stopPrank();

        // Check the shares
        assertEq(wrappedStTara.balanceOf(treasury), 1000 ether, "Treasury should have 1000 wrapped stTARA");
        uint256 shares = wrappedStTara.convertToShares(wrappedStTara.balanceOf(treasury));
        assertEq(shares, 1000 ether, "Shares should be 1000");

        // Mint another 1000 stTARA to a user
        stakedNativeAsset.mint(user, 1000 ether);

        // Wrap 1000 stTARA to the user
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), 1000 ether);
        wrappedStTara.deposit(1000 ether, user);
        vm.stopPrank();

        // Check the shares again
        assertEq(wrappedStTara.balanceOf(user), 1000 ether, "User should have 1000 wrapped stTARA");
        shares = wrappedStTara.convertToShares(wrappedStTara.balanceOf(user));
        assertEq(shares, 1000 ether, "Shares should be 1000");

        // Shares of the treasury should be half of the total supply
        assertEq(wrappedStTara.totalSupply(), 2000 ether, "Total supply should be 2000");
        assertEq(wrappedStTara.convertToShares(wrappedStTara.balanceOf(treasury)), 1000 ether, "Shares should be 1000");

        // Mint more stTARA to the wrapped stTARA
        stakedNativeAsset.mint(address(wrappedStTara), 1000 ether);

        // Check the shares again
        assertEq(wrappedStTara.totalSupply(), 2000 ether, " wstTARA total supply should be 2000");
        assertEq(
            stakedNativeAsset.totalSupply() - totalStakedNativeAssetSupplyInitial,
            3000 ether,
            " stTARA total supply should be 3000"
        );
        assertApproxEqAbs(
            wrappedStTara.maxWithdraw(treasury), 1500 ether, 100, "Treasury shares should be 1500 equally distributed"
        );
        assertApproxEqAbs(
            wrappedStTara.maxWithdraw(user), 1500 ether, 100, "User shares should be 1500 equally distributed"
        );

        // Withdraw the max amount for the treasury should be 1500 (deposit + half of the rebase)
        vm.startPrank(treasury);
        uint256 maxSharesTreasury = wrappedStTara.maxWithdraw(treasury);
        wrappedStTara.withdraw(maxSharesTreasury, treasury, treasury);
        vm.stopPrank();

        // Check the shares of the treasury
        assertEq(wrappedStTara.balanceOf(treasury), 0, "Treasury should have 0 wrapped stTARA");
        assertApproxEqAbs(stakedNativeAsset.balanceOf(treasury), 1500 ether, 100, "Treasury should have 1500 stTARA");

        // Withdraw the max amount for the user should be 1500 (deposit + half of the rebase)
        vm.startPrank(user);
        uint256 maxSharesUser = wrappedStTara.maxWithdraw(user);
        wrappedStTara.withdraw(maxSharesUser, user, user);
        vm.stopPrank();

        // Check the shares of the user
        assertEq(wrappedStTara.balanceOf(user), 0, "User should have 0 wrapped stTARA");
        assertApproxEqAbs(
            stakedNativeAsset.balanceOf(user) - totalStakedNativeAssetSupplyInitial,
            1500 ether,
            100,
            "User should have 1500 stTARA"
        );
    }

    // Corner Cases
    function test_Pass_ZeroDeposit() public {
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), 0);
        wrappedStTara.deposit(0, user);
        vm.stopPrank();
    }

    function test_MaxUint256Deposit() public {
        uint256 maxAmount = type(uint256).max;
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), maxAmount);
        vm.expectRevert(); // Should revert due to overflow in share calculation
        wrappedStTara.deposit(maxAmount, user);
        vm.stopPrank();
    }

    function test_DepositToZeroAddress() public {
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        vm.expectRevert(); // Should revert when trying to deposit to zero address
        wrappedStTara.deposit(STAKED_AMOUNT, address(0));
        vm.stopPrank();
    }

    // Fuzz Tests
    function testFuzz_DepositAndWithdraw(uint256 amount) public {
        // Bound the amount to reasonable values to avoid overflow
        amount = bound(amount, 1 ether, 1_000_000 ether);

        stakedNativeAsset.mint(user, amount);

        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), amount);
        wrappedStTara.deposit(amount, user);

        uint256 sharesReceived = wrappedStTara.balanceOf(user);
        assertGt(sharesReceived, 0, "Should receive non-zero shares");

        wrappedStTara.withdraw(sharesReceived, user, user);
        assertEq(wrappedStTara.balanceOf(user), 0, "Should have no shares after withdrawal");
        vm.stopPrank();
    }

    function testFuzz_RebaseAndWithdraw(uint256 rebaseAmount) public {
        // Bound the rebase amount to reasonable values
        rebaseAmount = bound(rebaseAmount, 0, 1_000_000 ether);

        // Initial setup
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        vm.stopPrank();

        // Simulate rebase by minting new tokens
        stakedNativeAsset.mint(address(wrappedStTara), rebaseAmount);

        vm.startPrank(user);
        uint256 maxWithdrawAmount = wrappedStTara.maxWithdraw(user);
        wrappedStTara.withdraw(maxWithdrawAmount, user, user);
        vm.stopPrank();

        assertEq(wrappedStTara.balanceOf(user), 0, "Should have no wrapped tokens after withdrawal");
        assertGe(stakedNativeAsset.balanceOf(user), STAKED_AMOUNT, "Should receive at least initial deposit amount");
    }

    // Invariant Tests
    function invariant_TotalSupplyMatchesUnderlyingBalance() public {
        uint256 totalUnderlying = stakedNativeAsset.balanceOf(address(wrappedStTara));
        uint256 totalShares = wrappedStTara.totalSupply();

        assertGe(totalUnderlying, totalShares, "Total underlying should always be >= total shares");
    }

    function invariant_WithdrawableAmountNeverExceedsTotalAssets() public {
        address[] memory holders = new address[](2);
        holders[0] = user;
        holders[1] = treasury;

        uint256 totalWithdrawable = 0;
        for (uint256 i = 0; i < holders.length; i++) {
            totalWithdrawable += wrappedStTara.maxWithdraw(holders[i]);
        }

        assertLe(
            totalWithdrawable,
            stakedNativeAsset.balanceOf(address(wrappedStTara)),
            "Total withdrawable should never exceed total assets"
        );
    }

    function test_ConvertToSharesAndAssets() public {
        // Test conversion with zero amount
        assertEq(wrappedStTara.convertToShares(0), 0, "Zero assets should convert to zero shares");
        assertEq(wrappedStTara.convertToAssets(0), 0, "Zero shares should convert to zero assets");

        // Test conversion with non-zero amount
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        vm.stopPrank();

        assertApproxEqAbs(
            wrappedStTara.convertToShares(STAKED_AMOUNT), STAKED_AMOUNT, 100, "Initial conversion should be 1:1"
        );
        assertApproxEqAbs(
            wrappedStTara.convertToAssets(STAKED_AMOUNT), STAKED_AMOUNT, 100, "Initial conversion should be 1:1"
        );

        // Test conversion after rebase
        stakedNativeAsset.mint(address(wrappedStTara), STAKED_AMOUNT); // 100% rebase
        assertApproxEqAbs(
            wrappedStTara.convertToAssets(STAKED_AMOUNT),
            STAKED_AMOUNT * 2,
            100,
            "Share value should double after 100% rebase"
        );
    }

    function test_MaxOperations() public {
        // Test maxDeposit
        uint256 maxDeposit = wrappedStTara.maxDeposit(user);
        assertEq(maxDeposit, type(uint256).max, "Should allow maximum possible deposit");

        // Test maxMint
        uint256 maxMint = wrappedStTara.maxMint(user);
        assertEq(maxMint, type(uint256).max, "Should allow maximum possible mint");

        // Test maxWithdraw with no balance
        assertEq(wrappedStTara.maxWithdraw(user), 0, "Should return 0 for account with no balance");

        // Test maxRedeem with no balance
        assertEq(wrappedStTara.maxRedeem(user), 0, "Should return 0 for account with no balance");

        // Test with balance
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        vm.stopPrank();

        assertEq(wrappedStTara.maxWithdraw(user), STAKED_AMOUNT, "Should return full amount for withdrawal");
        assertEq(wrappedStTara.maxRedeem(user), STAKED_AMOUNT, "Should return full amount for redemption");
    }

    function test_PreviewOperations() public {
        // Test preview deposit
        uint256 previewDeposit = wrappedStTara.previewDeposit(STAKED_AMOUNT);
        assertApproxEqAbs(previewDeposit, STAKED_AMOUNT, 100, "Preview deposit should match input initially");

        // Test preview mint
        uint256 previewMint = wrappedStTara.previewMint(STAKED_AMOUNT);
        assertApproxEqAbs(previewMint, STAKED_AMOUNT, 100, "Preview mint should match input initially");

        // Test preview withdraw
        uint256 previewWithdraw = wrappedStTara.previewWithdraw(STAKED_AMOUNT);
        assertApproxEqAbs(previewWithdraw, STAKED_AMOUNT, 100, "Preview withdraw should match input initially");

        // Test preview redeem
        uint256 previewRedeem = wrappedStTara.previewRedeem(STAKED_AMOUNT);
        assertApproxEqAbs(previewRedeem, STAKED_AMOUNT, 100, "Preview redeem should match input initially");

        // Test preview operations after rebase
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);
        wrappedStTara.deposit(STAKED_AMOUNT, user);
        vm.stopPrank();

        stakedNativeAsset.mint(address(wrappedStTara), STAKED_AMOUNT); // 100% rebase

        assertApproxEqAbs(
            wrappedStTara.previewWithdraw(STAKED_AMOUNT * 2),
            STAKED_AMOUNT,
            100,
            "Preview withdraw should account for rebase"
        );
        assertApproxEqAbs(
            wrappedStTara.previewDeposit(STAKED_AMOUNT),
            STAKED_AMOUNT / 2,
            100,
            "Preview deposit should account for rebase"
        );
    }

    function test_MintAndRedeem() public {
        vm.startPrank(user);
        stakedNativeAsset.approve(address(wrappedStTara), STAKED_AMOUNT);

        // Test mint
        uint256 sharesMinted = wrappedStTara.mint(STAKED_AMOUNT, user);
        assertEq(sharesMinted, STAKED_AMOUNT, "Should receive correct amount of shares");

        // Test redeem
        uint256 assetsRedeemed = wrappedStTara.redeem(STAKED_AMOUNT, user, user);
        assertEq(assetsRedeemed, STAKED_AMOUNT, "Should receive correct amount of assets");
        vm.stopPrank();
    }
}
