// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentProcessor.sol";

contract SwapIntentHelper {
    // Define the intent type for swap intents
    bytes public constant SWAP_INTENT_TYPE = "balance";

    // Function to prepare the Intent structure for a swap
    function prepareSwapIntent(
        address owner,
        address validator,
        uint32[] memory permissions,
        bytes[] memory permissionsPayload,
        bytes[] memory targetFields,
        bytes[] memory targetFieldsState,
        uint256 premium,
        uint256 expiration
    ) public pure returns (IIntentProcessor.Intent memory) {
        return
            IIntentProcessor.Intent({
                intentType: SWAP_INTENT_TYPE,
                owner: owner,
                validator: validator,
                permissions: permissions,
                permissionsPayload: permissionsPayload,
                targetFields: targetFields,
                targetFieldsState: targetFieldsState,
                premium: premium,
                expiration: expiration
            });
    }
}
