// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentValidator.sol";
import "../interfaces/IIntentProcessor.sol";
import "../interfaces/IIntentSolver.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../intent-parser/SwapIntentParser.sol";

contract SwapIntentValidator is IIntentValidator {
    modifier notExpired(IIntentProcessor.Intent calldata intent) {
        require(
            intent.expiration > block.number,
            "SwapIntentValidator: Intent expired"
        );
        _;
    }

    modifier isCorrectType(IIntentProcessor.Intent calldata intent) {
        require(
            keccak256(intent.operationType) ==
                keccak256(bytes("UniswapV3Swap")),
            "SwapIntentValidator: Incorrect intent type"
        );
        _;
    }

    function preview(
        IIntentProcessor.Intent calldata intent,
        address solver,
        bytes calldata payload
    )
        external
        view
        override
        notExpired(intent)
        isCorrectType(intent)
        returns (bool)
    {
        // Decode payload to get swap details
        (, , , , uint256 minOutputAmount, ) = abi.decode(
            payload,
            (string, uint256, address, address, uint256, address)
        );

        // Simulate the swap through the solver's preview solution
        bytes memory previewResult = IIntentSolver(solver).previewSolution(
            intent,
            payload
        );

        // Decode the preview result to get the expected output amount
        uint256 expectedOutputAmount = abi.decode(previewResult, (uint256));

        // Check if the expected output amount meets the minimum output amount criteria
        bool meetsCriteria = expectedOutputAmount >= minOutputAmount;

        return meetsCriteria;
    }
    function validate(
        bytes32 intentId,
        IIntentProcessor.Intent calldata intent,
        address solver,
        bytes calldata payload
    ) external override notExpired(intent) isCorrectType(intent) {
        // Decode payload to get swap details
        (
            ,
            uint256 amountIn,
            address assetFrom,
            address assetTo,
            uint256 minOutputAmount,
            address receiver
        ) = abi.decode(
                payload,
                (string, uint256, address, address, uint256, address)
            );

        // Check the balance of assetFrom and assetTo before the swap
        uint256 balanceFromBefore = IERC20(assetFrom).balanceOf(address(this));
        uint256 balanceToBefore = IERC20(assetTo).balanceOf(receiver);

        // Execute the swap through the solver
        IIntentSolver(solver).executeSolution(intentId, intent, payload);

        // Check the balance of assetFrom and assetTo after the swap
        uint256 balanceFromAfter = IERC20(assetFrom).balanceOf(address(this));
        uint256 balanceToAfter = IERC20(assetTo).balanceOf(receiver);

        // Ensure the receiver got at least minOutputAmount of assetTo
        require(
            balanceToAfter - balanceToBefore >= minOutputAmount,
            "SwapIntentValidator: Insufficient output amount"
        );

        // Ensure the exact amount of assetFrom is charged from the intent processor
        require(
            balanceFromBefore - balanceFromAfter == amountIn,
            "SwapIntentValidator: Incorrect amount charged"
        );
    }
}
