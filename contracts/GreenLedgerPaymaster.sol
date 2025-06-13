// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import OpenZeppelin contracts and GreenLedgerAccess
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GreenLedgerAccess.sol";
// import "./interface/IPaymaster.sol"; // Interface defined inline

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

// GreenLedgerPaymaster contract implementing IPaymaster
contract GreenLedgerPaymaster is IPaymaster {
    IEntryPointMinimal public immutable entryPoint;
    GreenLedgerAccess public immutable accessControl;
    
    mapping(address => bool) public allowedSenders;
    mapping(bytes4 => bool) public allowedOperations;
    
    event SenderStatusUpdated(address indexed sender, bool allowed);
    event OperationStatusUpdated(bytes4 indexed operation, bool allowed);
    event UserOperationSponsored(address indexed sender, bytes4 indexed operation, uint256 actualGasCost);
    
    constructor(IEntryPointMinimal _entryPoint, address _accessControlAddress) {
        require(_accessControlAddress != address(0), "Invalid access control address");
        entryPoint = _entryPoint;
        accessControl = GreenLedgerAccess(_accessControlAddress);
    }
    
    modifier onlyAdmin() {
        require(accessControl.hasRole(accessControl.ADMIN_ROLE(), msg.sender), "Caller is not admin");
        _;
    }
    
    function setSenderStatus(address sender, bool allowed) external onlyAdmin {
        allowedSenders[sender] = allowed;
        emit SenderStatusUpdated(sender, allowed);
    }
    
    function setBatchSenderStatus(address[] calldata senders, bool allowed) external onlyAdmin {
        for (uint256 i = 0; i < senders.length; i++) {
            allowedSenders[senders[i]] = allowed;
            emit SenderStatusUpdated(senders[i], allowed);
        }
    }
    
    function setOperationStatus(bytes4 operation, bool allowed) external onlyAdmin {
        allowedOperations[operation] = allowed;
        emit OperationStatusUpdated(operation, allowed);
    }
    
    function setBatchOperationStatus(bytes4[] calldata operations, bool allowed) external onlyAdmin {
        for (uint256 i = 0; i < operations.length; i++) {
            allowedOperations[operations[i]] = allowed;
            emit OperationStatusUpdated(operations[i], allowed);
        }
    }
    
    function deposit() public payable onlyAdmin {
        entryPoint.depositTo{value: msg.value}(address(this));
    }
    
    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyAdmin {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }
    
    function addStake(uint32 unstakeDelaySec) external payable onlyAdmin {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }
    
    function getDeposit() public view returns (uint256) {
        return entryPoint.balanceOf(address(this));
    }
    
    function unlockStake() external onlyAdmin {
        entryPoint.unlockStake();
    }
    
    function withdrawStake(address payable withdrawAddress) external onlyAdmin {
        entryPoint.withdrawStake(withdrawAddress);
    }
    
    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        _requireFromEntryPoint();
        
        bytes4 operationSelector;
        if (userOp.callData.length >= 4) {
            operationSelector = bytes4(userOp.callData[:4]);
        }
        
        require(allowedSenders[userOp.sender], "GreenLedgerPaymaster: Sender not allowed");
        require(allowedOperations[operationSelector], "GreenLedgerPaymaster: Operation not allowed");
        require(entryPoint.balanceOf(address(this)) >= maxCost, "GreenLedgerPaymaster: Insufficient deposit");
        
        return (abi.encode(operationSelector), 0);
    }
    
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external override {
        _requireFromEntryPoint();
        
        bytes4 operationSelector = abi.decode(context, (bytes4));
        emit UserOperationSponsored(msg.sender, operationSelector, actualGasCost);
    }
    
    function _requireFromEntryPoint() internal view {
        require(msg.sender == address(entryPoint), "GreenLedgerPaymaster: Caller is not EntryPoint");
    }
}