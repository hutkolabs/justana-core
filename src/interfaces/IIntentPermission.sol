// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIntentPermission {
    function add(bytes calldata payload) external;
    function remove(bytes calldata payload) external;
}
