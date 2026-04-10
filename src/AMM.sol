// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract AMM {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    LPToken public immutable lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpAmount);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpAmount);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken();
    }


    function getAmountOut(uint256 amountIn, bool isTokenA) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        uint256 resIn = isTokenA ? reserveA : reserveB;
        uint256 resOut = isTokenA ? reserveB : reserveA;

        // Apply 0.3% fee: amountIn * 997 / 1000
        uint256 amountInWithFee = (amountIn * 997);
        uint256 numerator = amountInWithFee * resOut;
        uint256 denominator = (resIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 lpAmount) {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 _totalSupply = lpToken.totalSupply();
        if (_totalSupply == 0) {
            lpAmount = _sqrt(amountA * amountB);
        } else {
            lpAmount = _min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
        }

        require(lpAmount > 0, "Insufficient liquidity minted");
        lpToken.mint(msg.sender, lpAmount);
        
        _updateReserves();
        emit LiquidityAdded(msg.sender, amountA, amountB, lpAmount);
    }

    function removeLiquidity(uint256 lpAmount) external returns (uint256 amountA, uint256 amountB) {
        uint256 _totalSupply = lpToken.totalSupply();
        amountA = (lpAmount * reserveA) / _totalSupply;
        amountB = (lpAmount * reserveB) / _totalSupply;

        lpToken.burn(msg.sender, lpAmount);
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        _updateReserves();
        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    function swap(uint256 amountIn, bool isTokenA, uint256 minAmountOut) external returns (uint256 amountOut) {
        amountOut = getAmountOut(amountIn, isTokenA);
        require(amountOut >= minAmountOut, "Slippage: Output below minimum");

        if (isTokenA) {
            tokenA.transferFrom(msg.sender, address(this), amountIn);
            tokenB.transfer(msg.sender, amountOut);
        } else {
            tokenB.transferFrom(msg.sender, address(this), amountIn);
            tokenA.transfer(msg.sender, amountOut);
        }

        _updateReserves();
        emit Swap(msg.sender, isTokenA ? address(tokenA) : address(tokenB), amountIn, amountOut);
    }

    function _updateReserves() private {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
