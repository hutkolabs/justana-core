// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/intent-stateless-permissions/ERC20ApprovalPermission.sol";
import "../src/intent-solver/SwapIntentSolver.sol";
import "../src/intent-validator/SwapIntentValidator.sol";
import "../src/intent-processor/IntentProcessor.sol";
import "../src/interfaces/ISwapRouter.sol";
import "../src/utils/SwapIntentHelper.sol";

contract MainScript is Script {
    ERC20ApprovalPermission internal erc20ApprovalPermission;
    SwapIntentSolver internal swapIntentSolver;
    SwapIntentValidator internal swapIntentValidator;
    IntentProcessor internal intentProcessor;

    ISwapRouter internal constant uniswapRouter =
        ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        erc20ApprovalPermission = new ERC20ApprovalPermission();
        swapIntentSolver = new SwapIntentSolver(uniswapRouter);
        intentProcessor = new IntentProcessor();
        swapIntentValidator = new SwapIntentValidator(intentProcessor);

        intentProcessor.addPermission(address(erc20ApprovalPermission));

        vm.stopBroadcast();
    }
}

contract HelperScript is Script {
    SwapIntentHelper internal swapIntentHelper;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        swapIntentHelper = new SwapIntentHelper();

        vm.stopBroadcast();
    }
}
