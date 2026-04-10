// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new MyToken("MyToken", "MTK");
    }

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), 1000000 * 10**18);
    }

    function test_Transfer() public {
        token.transfer(alice, 1000);
        assertEq(token.balanceOf(alice), 1000);
    }

    function test_BalanceAfterMint() public {
        token.mint(bob, 500);
        assertEq(token.balanceOf(bob), 500);
    }

    function test_TransferInsufficientBalance() public {
        vm.expectRevert(); 
        
        vm.prank(alice);
        token.transfer(bob, 1); 
    }

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount <= token.balanceOf(address(this)));
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_Invariant_TotalSupplyIsConstant() public view {
        assertEq(token.totalSupply(), 1000000 * 10**18);
    }
}
