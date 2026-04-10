// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
}

contract ForkTest is Test {
    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
    }

    function test_ReadRealUSDCData() public view {
        IERC20 usdc = IERC20(USDC_ADDRESS);
        
        uint256 supply = usdc.totalSupply();
        string memory name = usdc.name();

        console.log("Contract Name:", name);
        console.log("Real Mainnet USDC Supply:", supply);

        assertEq(name, "USD Coin");
        assertTrue(supply > 0);
    }

    function test_DemonstrateRollFork() public {
        uint256 targetBlock = 15_537_393; 
        
        vm.rollFork(targetBlock);
        
        console.log("Current block in fork:", block.number);
        assertEq(block.number, targetBlock);
    }
    function test_ComparisonExplanation() public pure {
        
    }
}
