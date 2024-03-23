// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SwapIntentParser {
    function parseSwapIntent(
        bytes memory data
    )
        public
        pure
        returns (
            string memory action,
            uint256 amountIn,
            address asset,
            address forAddress,
            uint256 minOutputAmount
        )
    {
        (action, amountIn, asset, forAddress, minOutputAmount) = abi.decode(
            data,
            (string, uint256, address, address, uint256)
        );
    }
}
