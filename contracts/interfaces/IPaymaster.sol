// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./PackedUserOperation.sol";

/**
 * @title IPaymaster
 * @dev Interface for the ERC-4337 Paymaster contract
 */
interface IPaymaster {
    /**
     * @dev Post operation modes
     */
    enum PostOpMode {
        opSucceeded, // User operation succeeded
        opReverted, // User operation reverted. Still has to pay for gas
        postOpReverted // Post operation reverted. Needs to revert the user operation
    }

    /**
     * @dev Validate the paymaster user operation
     * @param userOp The user operation
     * @param userOpHash The hash of the user operation
     * @param maxCost The maximum cost of the user operation
     * @return context The context for the paymaster
     * @return validationData The validation data
     */
    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);

    /**
     * @dev Post-operation handler
     * @param mode The post-operation mode
     * @param context The context from validatePaymasterUserOp
     * @param actualGasCost The actual gas cost of the operation
     * @param actualUserOpFeePerGas The actual fee per gas of the operation
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external;
}

