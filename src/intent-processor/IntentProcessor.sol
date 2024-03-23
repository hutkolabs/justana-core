// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentProcessor.sol";
import "../interfaces/IIntentValidator.sol";
import "../interfaces/IIntentPermission.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract IntentProcessor is IIntentProcessor {
    using Address for address payable;

    mapping(bytes32 => Intent) public intents;
    mapping(address => uint256) private solverPremiums;
    mapping(uint32 => address) public knownPermissions;
    uint32 public permissionCount = 0;
    mapping(address => bytes32[]) private userIntents;
    mapping(address => uint256) public userIntentCounts;

    constructor() {}

    function addPermission(address permission) external {
        uint32 permissionIndex = permissionCount + 1;
        require(
            knownPermissions[permissionIndex] == address(0),
            "Permission slot occupied"
        );
        knownPermissions[permissionIndex] = permission;
        permissionCount++;
    }

    function removePermission(uint32 permissionIndex) external {
        require(
            knownPermissions[permissionIndex] != address(0),
            "Permission not known"
        );
        delete knownPermissions[permissionIndex];
    }

    function placeIntent(
        Intent calldata intent
    ) external payable override returns (bytes32) {
        require(
            intent.expiration > block.number,
            "Expiration must be in the future"
        );
        require(
            msg.value == intent.premium,
            "Sent value must match the intent premium"
        );
        require(
            intent.permissions.length == intent.permissionsPayload.length,
            "Permissions count and payload mismatch"
        );

        require(
            intent.targetFields.length == intent.targetFieldsState.length,
            "Target fields and target fields state counts mismatch"
        );

        bytes32 intentId = keccak256(
            abi.encode(msg.sender, intent, block.number)
        );
        intents[intentId] = intent;
        userIntents[msg.sender].push(intentId);
        userIntentCounts[msg.sender]++;

        emit IntentPlaced(intentId, msg.sender);
        return intentId;
    }

    function executeIntent(
        address solver,
        bytes32 intentId,
        bytes calldata payload
    ) external override {
        Intent storage intent = intents[intentId];
        require(intent.expiration > block.number, "Intent expired");

        processPermissions(intent.permissions, intent.permissionsPayload, true);
        validateAndExecuteIntent(intentId, intent, solver, payload);
        processPermissions(
            intent.permissions,
            intent.permissionsPayload,
            false
        );

        solverPremiums[solver] += intent.premium;
        emit IntentExecuted(solver, intentId);
    }

    function withdrawPremium() external {
        uint256 premium = solverPremiums[msg.sender];
        require(premium > 0, "No premium to withdraw");
        solverPremiums[msg.sender] = 0;
        payable(msg.sender).sendValue(premium);
    }

    function previewIntent(
        address solver,
        bytes32 intentId,
        bytes calldata payload
    ) external view override returns (bool) {
        Intent storage intent = intents[intentId];
        require(intent.expiration > block.number, "Intent expired");
        IIntentValidator validator = IIntentValidator(intent.validator);
        return validator.preview(intent, solver, payload);
    }

    function getIntent(bytes32 intentId) external view returns (Intent memory) {
        return intents[intentId];
    }

    function getUserIntentByIndex(
        address user,
        uint256 index
    ) external view returns (bytes32) {
        require(index < userIntentCounts[user], "Index out of bounds");
        return userIntents[user][index];
    }

    // Helper functions
    function processPermissions(
        uint32[] memory permissions,
        bytes[] memory permissionsPayload,
        bool isAdding
    ) private {
        for (uint32 i = 0; i < permissions.length; i++) {
            address permissionContract = knownPermissions[permissions[i]];
            if (permissionContract != address(0)) {
                bytes memory data = isAdding
                    ? abi.encodeWithSelector(
                        IIntentPermission.add.selector,
                        permissionsPayload[i]
                    )
                    : abi.encodeWithSelector(
                        IIntentPermission.remove.selector,
                        permissionsPayload[i]
                    );

                (bool success, ) = permissionContract.delegatecall(data);
                require(success, "Permission processing failed");
            }
        }
    }

    function validateAndExecuteIntent(
        bytes32 intentId,
        Intent storage intent,
        address solver,
        bytes calldata payload
    ) private {
        IIntentValidator validator = IIntentValidator(intent.validator);
        require(
            validator.preview(intent, solver, payload),
            "Intent preview failed"
        );
        validator.validate(intentId, intent, solver, payload); // Reverts if validation fails
    }
}
