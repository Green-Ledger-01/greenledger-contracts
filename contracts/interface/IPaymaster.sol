// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Define PackedUserOperation struct
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

// Define IPaymaster interface
interface IPaymaster {
    enum PostOpMode {
        opSucceeded,
        opReverted,
        postOpReverted
    }

    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external;
}

// Define minimal IEntryPoint interface with only the functions used
interface IEntryPointMinimal {
    function depositTo(address account) external payable;
    function withdrawTo(address payable withdrawAddress, uint256 amount) external;
    function addStake(uint32 unstakeDelaySec) external payable;
    function balanceOf(address account) external view returns (uint256);
    function unlockStake() external;
    function withdrawStake(address payable withdrawAddress) external;
}