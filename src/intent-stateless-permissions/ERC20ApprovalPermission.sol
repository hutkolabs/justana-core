// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IIntentPermission.sol";

contract ERC20ApprovalPermission is IIntentPermission {
    function add(bytes calldata payload) external {
        (address tokenAddress, address spender, uint256 amount) = abi.decode(
            payload,
            (address, address, uint256)
        );
        IERC20(tokenAddress).approve(spender, amount);
    }

    function remove(bytes calldata payload) external {
        (address tokenAddress, address spender) = abi.decode(
            payload,
            (address, address)
        );
        IERC20(tokenAddress).approve(spender, 0);
    }
}
