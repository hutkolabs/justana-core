// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IIntentValidator.sol";
import "../interfaces/IIntentProcessor.sol";
import "../interfaces/IIntentSolver.sol";
import "../interfaces/IAIOracle.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../intent-parser/SwapIntentParser.sol";

contract AIIntentValidator {
    uint64 private constant AIORACLE_CALLBACK_GAS_LIMIT = 5000000;
    uint64 private constant DEFAULT_FEE = 0.03 ether;
    IAIOracle private constant aiOracle =
        IAIOracle(0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0);
    bytes private constant prompt =
        "Lool at the state transition and tell true or false only if it mets the following condition.";

    function useSecondAIFactor(
        IIntentProcessor.Intent calldata intent
    ) internal {
        aiOracle.requestCallback{value: DEFAULT_FEE}(
            11,
            prompt,
            address(this),
            AIORACLE_CALLBACK_GAS_LIMIT,
            bytes("")
        );
    }

    // function aiOracleCallback(
    //     uint256 requestId,
    //     bytes calldata output,
    //     bytes calldata callbackData
    // ) external virtual;
}
