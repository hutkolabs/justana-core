// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentProcessor.sol";
import "../interfaces/IIntentValidator.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract IntentProcessor is IIntentProcessor {
    using Address for address payable;

    mapping(bytes32 => Intent) public intents;
    mapping(address => uint256) private solverPremiums;
    mapping(uint32 => address) public knownPermissions;
    uint32 public permissionCount = 0;

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

    // Updated method to remove a permission from the known permissions
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

        bytes32 intentId = keccak256(
            abi.encode(msg.sender, intent, block.number)
        );
        intents[intentId] = intent;

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
        // dev: anyone can execute the intent as soon as it matches requirements
        // require(intent.validator == msg.sender, "Only validator can execute");

        IIntentValidator validator = IIntentValidator(intent.validator);
        // Use Validator to prevalidate (preview) the intent
        require(
            validator.preview(intent, solver, payload),
            "Intent preview failed"
        );

        // Assuming the validation logic is implemented in the Validator contract
        validator.validate(intentId, intent, solver, payload); // This will revert if validation fails

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
}
