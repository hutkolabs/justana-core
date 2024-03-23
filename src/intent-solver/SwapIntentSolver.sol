// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentSolver.sol";
import "../interfaces/IIntentProcessor.sol";
import "../utils/UniswapV3Utils.sol";
import "../intent-parser/SwapIntentParser.sol";

contract SwapIntentSolver is IIntentSolver, UniswapV3Utils {
    string public constant FIELDS_TO_OPTIMISE = "amountOut,amountIn";
    bytes public constant INTENT_TYPE = "balance";

    constructor(ISwapRouter _swapRouter) UniswapV3Utils(_swapRouter) {}

    modifier validOperationType(IIntentProcessor.Intent calldata intent) {
        require(
            keccak256(bytes(intent.intentType)) ==
                keccak256(bytes(INTENT_TYPE)),
            "Invalid optimization fields"
        );

        _;
    }

    function previewSolution(
        IIntentProcessor.Intent calldata intent,
        bytes calldata payload
    )
        external
        view
        override
        returns (
            // validOptimizationFields(intent)
            bytes memory
        )
    {
        // Use SwapIntentParser to parse intent.payload
        (
            ,
            uint256 amountIn,
            address asset,
            address forAddress,
            uint256 minOutputAmount,

        ) = SwapIntentParser.parseSwapIntent(payload);

        // Assuming poolAddress, tokenIn, tokenOut, and fee are known or derived from context
        // This is a placeholder for actual swap preview logic, which would depend on the specific implementation
        uint amountOut = UniswapV3Utils.previewSwapExactInputSingle(
            asset,
            forAddress,
            amountIn
        );

        require(amountOut >= minOutputAmount, "Insufficient output amount");

        return abi.encode(amountOut);
    }

    function executeSolution(
        bytes32 intentId,
        IIntentProcessor.Intent calldata intent,
        bytes calldata payload
    )
        external
        override
        validOperationType(intent)
    // validOptimizationFields(intent)
    {
        // Use SwapIntentParser to parse intent.payload
        (
            ,
            uint256 amountIn,
            address assetFrom,
            address assetTo,
            uint256 minOutputAmount,
            address receiver
        ) = SwapIntentParser.parseSwapIntent(payload);

        // Execute the swap with the parsed parameters
        uint amountOut = UniswapV3Utils.swapExactInputSingle(
            assetFrom,
            assetTo,
            amountIn,
            receiver
        );

        require(amountOut >= minOutputAmount, "Insufficient output amount");

        emit SolutionExecuted(intentId, msg.sender);
    }
}
