// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PackedUserOperation
 * @dev User Operation struct used by the EntryPoint contract
 */
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    bytes32 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}

