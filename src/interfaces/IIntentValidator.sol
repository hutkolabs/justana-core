// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IIntentProcessor.sol";

interface IIntentValidator {
    /**
     * @dev Preview the intent to check if it meets certain criteria.
     * @param intent The intent to be checked.
     * @param solver The address of the solver.
     * @param payload The payload associated with the intent.
     * @return A boolean indicating whether the intent meets the criteria.
     */
    function preview(
        IIntentProcessor.Intent calldata intent,
        address solver,
        bytes calldata payload
    ) external view returns (bool);

    /**
     * @dev Validate the intent to ensure it meets the optimized parameters criteria.
     * Reverts if the criteria are not met.
     * @param intent The intent to be validated.
     * @param solver The address of the solver.
     * @param payload The payload associated with the intent.
     */
    function validate(
        IIntentProcessor.Intent calldata intent,
        address solver,
        bytes calldata payload
    ) external;
}
