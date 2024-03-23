// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IIntentProcessor.sol";

interface ISolver {
    /**
     * @dev Emitted when a solution preview is requested.
     * @param intentId The unique identifier of the intent being previewed.
     * @param solver The address of the solver performing the preview.
     */
    event SolutionPreviewRequested(
        bytes32 indexed intentId,
        address indexed solver
    );

    /**
     * @dev Emitted when a solution is executed.
     * @param intentId The unique identifier of the intent being executed.
     * @param solver The address of the solver executing the solution.
     */
    event SolutionExecuted(bytes32 indexed intentId, address indexed solver);

    /**
     * @dev Preview the solution for a given intent.
     * @param intent The intent to be optimized and previewed.
     * @return A bytes array containing the results of the optimized fields.
     */
    function previewSolution(
        IIntentProcessor.Intent calldata intent,
        bytes calldata payload
    ) external view returns (bytes memory);

    /**
     * @dev Execute the solution for a given intent.
     * @param intent The intent to be executed as proposed.
     */
    function executeSolution(
        IIntentProcessor.Intent calldata intent,
        bytes calldata payload
    ) external;
}
