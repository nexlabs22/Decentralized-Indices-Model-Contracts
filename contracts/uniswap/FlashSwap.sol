// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "../interfaces/IWETH.sol";
contract FlashSwap {

    address public swapRouterAddress;
    address public wethAddress;

    // NOTE: Does not work with SwapRouter02
    ISwapRouter public swapRouter;


    constructor(
        address _wethAddress,
        address _swapRouterAddress

    ) {
        wethAddress = _wethAddress;
        swapRouterAddress = _swapRouterAddress;
        swapRouter = ISwapRouter(swapRouterAddress);

    }
    


    function swapExactInputSingleFromETH(uint amountIn, address _tokenOut)
        payable
        external
        returns (uint amountOut)
    {
        IWETH(wethAddress).deposit{value: msg.value}();
        TransferHelper.safeApprove(wethAddress, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: wethAddress,
            tokenOut: _tokenOut,
            // pool fee 0.3%
            fee: 3000,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactInputSingleToETH(uint amountIn, address _tokenIn)
        external
        returns (uint amountOut)
    {
        TransferHelper.safeTransferFrom(
            _tokenIn,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: wethAddress,
            // pool fee 0.3%
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });

        amountOut = swapRouter.exactInputSingle(params);

        // Withdraw WETH to msg.sender
        IWETH(wethAddress).withdraw(amountOut);
        (bool _requesterSuccess, ) = address(msg.sender).call{value: amountOut}("");
        require(_requesterSuccess, "transfer eth to the requester failed");
    }

    /// @notice Swaps a fixed amount of WETH for a maximum possible amount of DAI
    function swapExactInputSingle(address _tokenIn, uint amountIn, address _tokenOut)
        external
        returns (uint amountOut)
    {
        TransferHelper.safeTransferFrom(
            _tokenIn,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            // pool fee 0.3%
            fee: 3000,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);
    }

     






    
}