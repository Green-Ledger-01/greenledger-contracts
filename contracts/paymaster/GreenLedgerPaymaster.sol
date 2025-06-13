// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPaymaster.sol";
import "../interfaces/IEntryPoint.sol";

/**
 * @title GreenLedgerPaymaster
 * @dev A paymaster contract for the GreenLedger DApp that allows for gasless transactions.
 * This paymaster sponsors gas fees for agricultural supply chain operations.
 */
contract GreenLedgerPaymaster is IPaymaster, Ownable2Step {
    IEntryPoint public immutable entryPoint;
    
    // Mapping to track which addresses are allowed to use this paymaster
    mapping(address => bool) public allowedSenders;
    
    // Mapping to track which operations are allowed to be sponsored
    mapping(bytes4 => bool) public allowedOperations;
    
    // Events
    event SenderStatusUpdated(address indexed sender, bool allowed);
    event OperationStatusUpdated(bytes4 indexed operation, bool allowed);
    event UserOperationSponsored(address indexed sender, bytes4 indexed operation, uint256 actualGasCost);
    
    /**
     * @dev Constructor
     * @param _entryPoint The EntryPoint contract address
     */
    constructor(IEntryPoint _entryPoint) Ownable(msg.sender) {
        entryPoint = _entryPoint;
    }
    
    /**
     * @dev Set the allowed status for a sender
     * @param sender The address to update
     * @param allowed Whether the sender is allowed to use this paymaster
     */
    function setSenderStatus(address sender, bool allowed) external onlyOwner {
        allowedSenders[sender] = allowed;
        emit SenderStatusUpdated(sender, allowed);
    }
    
    /**
     * @dev Set the allowed status for multiple senders
     * @param senders The addresses to update
     * @param allowed Whether the senders are allowed to use this paymaster
     */
    function setBatchSenderStatus(address[] calldata senders, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < senders.length; i++) {
            allowedSenders[senders[i]] = allowed;
            emit SenderStatusUpdated(senders[i], allowed);
        }
    }
    
    /**
     * @dev Set the allowed status for an operation
     * @param operation The operation selector to update
     * @param allowed Whether the operation is allowed to be sponsored
     */
    function setOperationStatus(bytes4 operation, bool allowed) external onlyOwner {
        allowedOperations[operation] = allowed;
        emit OperationStatusUpdated(operation, allowed);
    }
    
    /**
     * @dev Set the allowed status for multiple operations
     * @param operations The operation selectors to update
     * @param allowed Whether the operations are allowed to be sponsored
     */
    function setBatchOperationStatus(bytes4[] calldata operations, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < operations.length; i++) {
            allowedOperations[operations[i]] = allowed;
            emit OperationStatusUpdated(operations[i], allowed);
        }
    }
    
    /**
     * @dev Add a deposit for this paymaster, used for paying for transaction fees
     */
    function deposit() public payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }
    
    /**
     * @dev Withdraw value from the deposit
     * @param withdrawAddress Target to send to
     * @param amount Amount to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }
    
    /**
     * @dev Add stake for this paymaster
     * @param unstakeDelaySec The unstake delay for this paymaster
     */
    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }
    
    /**
     * @dev Return current paymaster's deposit on the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint.balanceOf(address(this));
    }
    
    /**
     * @dev Unlock the stake, in order to withdraw it
     */
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }
    
    /**
     * @dev Withdraw the entire paymaster's stake
     * @param withdrawAddress The address to send withdrawn value
     */
    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
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
    ) external override returns (bytes memory context, uint256 validationData) {
        _requireFromEntryPoint();
        
        // Extract the first 4 bytes from callData to get the function selector
        bytes4 operationSelector;
        if (userOp.callData.length >= 4) {
            operationSelector = bytes4(userOp.callData[:4]);
        }
        
        // Check if the sender is allowed to use this paymaster
        require(allowedSenders[userOp.sender], "GreenLedgerPaymaster: Sender not allowed");
        
        // Check if the operation is allowed to be sponsored
        require(allowedOperations[operationSelector], "GreenLedgerPaymaster: Operation not allowed");
        
        // Check if the paymaster has enough deposit to pay for the max cost
        require(entryPoint.balanceOf(address(this)) >= maxCost, "GreenLedgerPaymaster: Insufficient deposit");
        
        // Return empty context and validation data
        return (abi.encode(operationSelector), 0);
    }
    
    /**
     * @dev Post-operation handler
     * @param mode The post-operation mode
     * @param context The context from validatePaymasterUserOp
     * @param actualGasCost The actual gas cost of the operation
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external override {
        _requireFromEntryPoint();
        
        // Decode the context to get the operation selector
        bytes4 operationSelector = abi.decode(context, (bytes4));
        
        // Emit event for the sponsored operation
        emit UserOperationSponsored(msg.sender, operationSelector, actualGasCost);
    }
    
    /**
     * @dev Validate the call is made from a valid entrypoint
     */
    function _requireFromEntryPoint() internal view {
        require(msg.sender == address(entryPoint), "GreenLedgerPaymaster: Caller is not EntryPoint");
    }
}

