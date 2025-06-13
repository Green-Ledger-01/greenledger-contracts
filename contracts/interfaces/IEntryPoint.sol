// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PackedUserOperation.sol";
import "./IStakeManager.sol";
import "./INonceManager.sol";

/**
 * @title IEntryPoint
 * @dev Interface for the ERC-4337 EntryPoint contract
 */
interface IEntryPoint is IStakeManager, INonceManager {
    /**
     * @dev Emitted when a user operation is started
     */
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        bool success,
        uint256 actualGasCost,
        uint256 actualGasUsed
    );

    /**
     * @dev Emitted when a user operation is started
     */
    event AccountDeployed(
        bytes32 indexed userOpHash,
        address indexed sender,
        address factory,
        address paymaster
    );

    /**
     * @dev Emitted when a signature aggregator is changed
     */
    event SignatureAggregatorChanged(address indexed aggregator);

    /**
     * @dev Emitted before a user operation is executed
     */
    event BeforeExecution();

    /**
     * @dev Error thrown when the signature validation fails
     */
    error SignatureValidationFailed(address aggregator);

    /**
     * @dev Error thrown when the operation reverts with a specific reason
     */
    error FailedOp(uint256 opIndex, string reason);

    /**
     * @dev Error thrown when the sender address result is returned
     */
    error SenderAddressResult(address sender);

    /**
     * @dev Error thrown when the delegate and revert operation is performed
     */
    error DelegateAndRevert(bool success, bytes ret);

    /**
     * @dev Handle a batch of user operations
     * @param ops The user operations to handle
     * @param beneficiary The address to receive the fees
     */
    function handleOps(
        PackedUserOperation[] calldata ops,
        address payable beneficiary
    ) external;

    /**
     * @dev Handle a batch of user operations with aggregated signatures
     * @param opsPerAggregator The user operations per aggregator
     * @param beneficiary The address to receive the fees
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * @dev Get the hash of a user operation
     * @param userOp The user operation
     * @return The hash of the user operation
     */
    function getUserOpHash(PackedUserOperation calldata userOp) external view returns (bytes32);

    /**
     * @dev Get the sender address from the init code
     * @param initCode The init code
     */
    function getSenderAddress(bytes calldata initCode) external;

    /**
     * @dev Get the sender creator contract
     * @return The sender creator contract
     */
    function senderCreator() external view returns (address);

    /**
     * @dev Delegate and revert
     * @param target The target address
     * @param data The data to delegate
     */
    function delegateAndRevert(address target, bytes calldata data) external;
}

/**
 * @title UserOpsPerAggregator
 * @dev User operations per aggregator struct
 */
struct UserOpsPerAggregator {
    PackedUserOperation[] userOps;
    address aggregator;
    bytes signature;
}

