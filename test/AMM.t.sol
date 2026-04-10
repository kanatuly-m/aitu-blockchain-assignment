// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "../src/MyToken.sol";

contract AMMTest is Test {
    AMM amm;
    MyToken tokenA;
    MyToken tokenB;
    address lpProvider = address(0x111);
    address swapper = address(0x222);

    function setUp() public {
        tokenA = new MyToken("Token A", "TKA");
        tokenB = new MyToken("Token B", "TKB");
        amm = new AMM(address(tokenA), address(tokenB));

        tokenA.mint(lpProvider, 1000e18);
        tokenB.mint(lpProvider, 1000e18);
        tokenA.mint(swapper, 100e18);
        tokenB.mint(swapper, 100e18);

        vm.startPrank(lpProvider);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(swapper);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    function test_InitialLiquidity() public {
        vm.prank(lpProvider);
        amm.addLiquidity(100e18, 100e18);
        assertEq(amm.lpToken().balanceOf(lpProvider), 100e18);
    }

    function test_SubsequentLiquidity() public {
        vm.startPrank(lpProvider);
        amm.addLiquidity(100e18, 100e18);
        amm.addLiquidity(50e18, 50e18);
        vm.stopPrank();
        assertEq(amm.lpToken().balanceOf(lpProvider), 150e18);
    }

    function test_RemoveFullLiquidity() public {
        vm.startPrank(lpProvider);
        amm.addLiquidity(100e18, 100e18);
        amm.removeLiquidity(100e18);
        vm.stopPrank();
        assertEq(amm.lpToken().balanceOf(lpProvider), 0);
        assertEq(tokenA.balanceOf(lpProvider), 1000e18);
    }

    function test_SwapAtoB() public {
        vm.prank(lpProvider);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(swapper);
        uint256 out = amm.swap(10e18, true, 0);
        assertTrue(out > 0);
        assertEq(tokenB.balanceOf(swapper), 100e18 + out);
    }

    function test_SwapBtoA() public {
        vm.prank(lpProvider);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(swapper);
        uint256 out = amm.swap(10e18, false, 0);
        assertTrue(out > 0);
    }

    function test_InvariantK_IncreasesDueToFees() public {
        vm.prank(lpProvider);
        amm.addLiquidity(100e18, 100e18);
        uint256 kBefore = amm.reserveA() * amm.reserveB();

        vm.prank(swapper);
        amm.swap(10e18, true, 0);

        uint256 kAfter = amm.reserveA() * amm.reserveB();
        assertTrue(kAfter > kBefore, "K should increase due to 0.3% fee");
    }

    function test_SlippageProtection_Revert() public {
        vm.prank(lpProvider);
        amm.addLiquidity(100e18, 100e18);

        uint256 expectedOut = amm.getAmountOut(10e18, true);
        vm.prank(swapper);
        vm.expectRevert("Slippage: Output below minimum");
        amm.swap(10e18, true, expectedOut + 1);
    }

    function test_FailZeroAmountAdd() public {
        vm.prank(lpProvider);
        vm.expectRevert();
        amm.addLiquidity(0, 100e18);
    }

    function testFuzz_SwapOutput(uint256 amountIn) public {
        vm.assume(amountIn > 1000 && amountIn < 10e18);
        vm.prank(lpProvider);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(swapper);
        uint256 out = amm.swap(amountIn, true, 0);
        assertTrue(out > 0);
    }
}
