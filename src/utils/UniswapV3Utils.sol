// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ISwapRouter.sol";

contract UniswapV3Utils {
    using SafeERC20 for IERC20;

    ISwapRouter public immutable swapRouter;

    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of one token for a maximum possible amount of another token
    /// using a specified pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its input token for this function to succeed.
    /// @param tokenIn The address of the token being swapped from.
    /// @param tokenOut The address of the token being swapped to.
    /// @param amountIn The exact amount of tokenIn that will be swapped for tokenOut.
    /// @param receiver The address to receive the tokenOut.
    /// @return amountOut The amount of tokenOut received.
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // TODO: use safe approve
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: receiver,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of one token for a fixed amount of another token.
    /// @dev The calling address must approve this contract to spend its input token for this function to succeed.
    /// @param tokenIn The address of the token being swapped from.
    /// @param tokenOut The address of the token being swapped to.
    /// @param amountOut The exact amount of tokenOut to receive from the swap.
    /// @param amountInMaximum The maximum amount of tokenIn we are willing to spend to receive the specified amount of tokenOut.
    /// @param receiver The address to receive the tokenOut.
    /// @return amountIn The amount of tokenIn actually spent in the swap.
    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum,
        address receiver
    ) internal returns (uint256 amountIn) {
        IERC20(tokenIn).safeTransferFrom(
            msg.sender,
            address(this),
            amountInMaximum
        );

        // TODO: use safe approves
        IERC20(tokenIn).approve(address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: receiver,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);

        if (amountIn < amountInMaximum) {
            // TODO: use safe approve
            IERC20(tokenIn).approve(address(swapRouter), 0);
            IERC20(tokenIn).safeTransfer(
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }

    // TODO: implement this
    /// @notice previewSwapExactInputSingle previews the output amount for a given input amount of one token for another token.
    /// @dev This function is a placeholder and should be replaced with actual logic to preview a swap on Uniswap V3.
    /// @param _tokenIn The address of the token being swapped from.
    /// @param _tokenOut The address of the token being swapped to.
    /// @param _amountIn The amount of tokenIn to swap.
    /// @return amountOut The estimated amount of tokenOut to receive from the swap.
    function previewSwapExactInputSingle(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) public view returns (uint256 amountOut) {
        // Placeholder logic for swap preview
        // In a real implementation, this function would interact with Uniswap V3 contracts to get a quote for the swap.
        // For demonstration purposes, we're returning the input amount as the output amount.
        // This should be replaced with actual logic to preview a swap on Uniswap V3.
        amountOut = type(uint256).max;
    }
}
