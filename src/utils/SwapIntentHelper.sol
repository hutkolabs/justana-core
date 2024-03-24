// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentProcessor.sol";
import "../intent-validator/SwapIntentValidator.sol";

contract SwapIntentHelper {
    // Define the intent type for swap intents
    bytes public constant SWAP_INTENT_TYPE = "balance";

    function encodePermissionPayload(
        address tokenAddress,
        address spender,
        uint256 amount
    ) public pure returns (bytes memory) {
        return abi.encode(tokenAddress, spender, amount);
    }

    function encodeTargetField(
        address tokenAddress
    ) public pure returns (bytes memory) {
        return abi.encode(tokenAddress);
    }

    function encodeSwap(
        uint256 amountIn,
        address assetIn,
        address assetTo,
        uint256 minAmountOut,
        address receiver
    ) public pure returns (bytes memory) {
        return abi.encode(amountIn, assetIn, assetTo, minAmountOut, receiver);
    }

    function encodeTargetFieldsState(
        SwapIntentValidator.Operator operator,
        uint256 value
    ) public pure returns (bytes memory) {
        return abi.encode(operator, value);
    }

    function encodeSwapIntent(
        address[] memory permissionTokenAddresses,
        address[] memory permissionSpenders,
        uint256[] memory permissionAmounts,
        address[] memory targetFieldAddresses,
        SwapIntentValidator.Operator[] memory targetFieldOperators,
        uint256[] memory targetFieldValues
    ) public pure returns (bytes[] memory, bytes[] memory, bytes[] memory) {
        bytes[] memory permissionsPayload = new bytes[](
            permissionTokenAddresses.length
        );
        for (uint256 i = 0; i < permissionTokenAddresses.length; i++) {
            permissionsPayload[i] = encodePermissionPayload(
                permissionTokenAddresses[i],
                permissionSpenders[i],
                permissionAmounts[i]
            );
        }

        bytes[] memory targetFields = new bytes[](targetFieldAddresses.length);
        for (uint256 i = 0; i < targetFieldAddresses.length; i++) {
            targetFields[i] = encodeTargetField(targetFieldAddresses[i]);
        }

        bytes[] memory targetFieldsState = new bytes[](
            targetFieldOperators.length
        );
        for (uint256 i = 0; i < targetFieldOperators.length; i++) {
            targetFieldsState[i] = encodeTargetFieldsState(
                targetFieldOperators[i],
                targetFieldValues[i]
            );
        }

        return (permissionsPayload, targetFields, targetFieldsState);
    }
}
