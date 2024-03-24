// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SwapIntentParser {
    function parseSwapIntent(
        bytes memory data
    )
        public
        pure
        returns (
            uint256 amountIn,
            address assetIn,
            address assetTo,
            uint256 minAmountOut,
            address receiver
        )
    {
        (amountIn, assetIn, assetTo, minAmountOut, receiver) = abi.decode(
            data,
            (uint256, address, address, uint256, address)
        );
    }
}
