// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentValidator.sol";
import "../interfaces/IIntentProcessor.sol";
import "../interfaces/IIntentSolver.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../intent-parser/SwapIntentParser.sol";
import "./AIIntentValidator.sol";

contract SwapIntentValidator is IIntentValidator, AIIntentValidator {
    using SafeERC20 for IERC20;
    bytes public constant INTENT_TYPE = "balance";

    enum Operator {
        StrictlyLessBy,
        LessBy,
        Equal,
        BiggerBy,
        StrictlyBiggerBy
    }

    struct BalanceStateRequest {
        address token;
        Operator op;
        uint256 value;
        uint256 balanceBefore;
        uint256 balanceAfter;
    }

    modifier notExpired(IIntentProcessor.Intent calldata intent) {
        require(
            intent.expiration > block.number,
            "SwapIntentValidator: Intent expired"
        );
        _;
    }

    modifier isCorrectType(IIntentProcessor.Intent calldata intent) {
        require(
            keccak256(intent.intentType) == keccak256(bytes(INTENT_TYPE)),
            "SwapIntentValidator: Incorrect intent type"
        );
        _;
    }

    constructor(IIntentProcessor ip) AIIntentValidator(ip) {}

    function parseTargetStateData(
        IIntentProcessor.Intent calldata intent,
        address solver
    ) internal returns (BalanceStateRequest[] memory balanceStateRequest) {
        balanceStateRequest = new BalanceStateRequest[](
            intent.targetFieldsState.length
        );

        for (uint256 i = 0; i < intent.targetFieldsState.length; i++) {
            (Operator operator, uint256 value) = abi.decode(
                intent.targetFieldsState[i],
                (Operator, uint256)
            );
            address token = abi.decode(intent.targetFields[i], (address));
            address balanceAddress = msg.sender;

            if (
                operator == Operator.StrictlyLessBy ||
                operator == Operator.LessBy
            ) {
                // Transfer from for input amount of token
                // dev: the assets that may be used will be send to the contract directly which is insecure.
                // TODO: improve approve - transferfrom logic, use proxies per user
                IERC20(token).safeTransferFrom(
                    msg.sender,
                    address(this),
                    value
                );

                // Safe approval for spent token
                IERC20(token).approve(solver, value);
                balanceAddress = address(this);
            }
            balanceStateRequest[i] = BalanceStateRequest({
                token: token,
                op: operator,
                value: value,
                balanceBefore: IERC20(token).balanceOf(balanceAddress),
                balanceAfter: 0 // Will be updated after the swap
            });
        }
    }

    function processBalanceAdjustmentsAfterSwap(
        BalanceStateRequest[] memory balanceStateRequests,
        address receiver
    ) internal view {
        for (uint256 i = 0; i < balanceStateRequests.length; i++) {
            BalanceStateRequest memory request = balanceStateRequests[i];

            // Update after balance
            address balanceAddress = request.op == Operator.StrictlyLessBy ||
                request.op == Operator.LessBy
                ? address(this)
                : receiver;
            request.balanceAfter = IERC20(request.token).balanceOf(
                balanceAddress
            );
        }
    }

    function validate(
        bytes32 intentId,
        IIntentProcessor.Intent calldata intent,
        address solver,
        bytes calldata payload
    ) external override notExpired(intent) isCorrectType(intent) {
        // Decode payload to get state requirements
        BalanceStateRequest[]
            memory balanceStateRequests = parseTargetStateData(intent, solver);

        // Execute the swap through the solver
        IIntentSolver(solver).executeSolution(intentId, intent, payload);

        // Process balance adjustments and update after balances
        processBalanceAdjustmentsAfterSwap(balanceStateRequests, intent.owner);

        // TODO: Check if the requirements are met by including value
        for (uint256 i = 0; i < balanceStateRequests.length; i++) {
            BalanceStateRequest memory request = balanceStateRequests[i];
            bool requirementMet;
            if (request.op == Operator.StrictlyLessBy) {
                requirementMet = request.balanceAfter < request.balanceBefore;
            } else if (request.op == Operator.LessBy) {
                requirementMet = request.balanceAfter <= request.balanceBefore;
            } else if (request.op == Operator.Equal) {
                requirementMet = request.balanceAfter == request.balanceBefore;
            } else if (request.op == Operator.BiggerBy) {
                requirementMet = request.balanceAfter >= request.balanceBefore;
            } else if (request.op == Operator.StrictlyBiggerBy) {
                requirementMet = request.balanceAfter > request.balanceBefore;
            }
            require(
                requirementMet,
                "SwapIntentValidator: Requirement not met for a token"
            );
        }
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
}
//     (, , , , uint256 minOutputAmount, ) = abi.decode(
//         payload,
//         (string, uint256, address, address, uint256, address)
//     );

//     // Simulate the swap through the solver's preview solution
//     bytes memory previewResult = IIntentSolver(solver).previewSolution(
//         intent,
//         payload
//     );

//     // Decode the preview result to get the expected output amount
//     uint256 expectedOutputAmount = abi.decode(previewResult, (uint256));

//     // Check if the expected output amount meets the minimum output amount criteria
//     bool meetsCriteria = expectedOutputAmount >= minOutputAmount;

//     return meetsCriteria;
// }
// function validate(
//     bytes32 intentId,
//     IIntentProcessor.Intent calldata intent,
//     address solver,
//     bytes calldata payload
// ) external override notExpired(intent) isCorrectType(intent) {
//     // Decode payload to get state requirements
//     BalanceStateRequest[] memory balanceStateRequest = parseTargetStateData(
//         intent
//     );

//     // Execute the swap through the solver
//     IIntentSolver(solver).executeSolution(intentId, intent, payload);

//     // Check the balance of assetFrom and assetTo after the swap
//     uint256 balanceFromAfter = IERC20(assetFrom).balanceOf(address(this));
//     uint256 balanceToAfter = IERC20(assetTo).balanceOf(receiver);

//     // Ensure the receiver got at least minOutputAmount of assetTo
//     require(
//         balanceToAfter - balanceToBefore >= minOutputAmount,
//         "SwapIntentValidator: Insufficient output amount"
//     );

//     // Ensure the exact amount of assetFrom is charged from the intent processor
//     require(
//         balanceFromBefore - balanceFromAfter == amountIn,
//         "SwapIntentValidator: Incorrect amount charged"
//     );
// }
// }
