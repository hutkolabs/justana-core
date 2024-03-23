// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IIntentProcessor
 * @dev Interface for processing intents within a decentralized system.
 */
interface IIntentProcessor {
    /**
     * @dev Struct to represent an intent within the system.
     * @param operationType The type of operation to be performed, encoded in bytes.
     * @param validator The address or ID of the validator for the intent.
     * @param fieldsToOptimize The specific fields targeted for optimization, encoded in bytes.
     * @param optimizationNote A string containing notes for optimization, typically in the format [field][operator][value].
     * @param payload The payload associated with the intent, encoded in bytes.
     * @param premium The premium amount in wei to be paid for the intent.
     * @param expiration The expiration block height of the intent.
     */
    struct Intent {
        bytes operationType;
        address validator;
        string fieldsToOptimize;
        string optimizationNote;
        bytes payload;
        uint256 premium;
        uint256 expiration;
    }

    /**
     * @dev Emitted when an intent is placed.
     * @param intentId The unique identifier of the intent.
     * @param creator The address of the creator of the intent.
     */
    event IntentPlaced(bytes32 indexed intentId, address indexed creator);

    /**
     * @dev Emitted when an intent is executed.
     * @param solver The address of the solver who performed the intent.
     * @param intentId The unique identifier of the intent.
     */
    event IntentExecuted(address indexed solver, bytes32 indexed intentId);

    /**
     * @dev Function to place an intent within the system.
     * @param intent The Intent struct containing details about the intent.
     * @return The unique identifier of the placed intent.
     */
    function placeIntent(
        Intent calldata intent
    ) external payable returns (bytes32);

    /**
     * @dev Function to execute an intent by providing the solver's address and the payload.
     * @param solver The address of the solver attempting to perform the intent.
     * @param intentId The unique identifier of the intent to be executed.
     * @param payload The payload associated with the intent, encoded in bytes.
     */
    function executeIntent(
        address solver,
        bytes32 intentId,
        bytes calldata payload
    ) external;

    /**
     * @dev Function to preview an intent before execution, considering the solver and payload.
     * @param solver The address of the solver attempting to preview the intent.
     * @param intentId The unique identifier of the intent to be previewed.
     * @param payload The payload associated with the intent, encoded in bytes.
     * @return A boolean indicating whether the intent meets the validator's criteria for execution.
     */
    function previewIntent(
        address solver,
        bytes32 intentId,
        bytes calldata payload
    ) external view returns (bool);
}
