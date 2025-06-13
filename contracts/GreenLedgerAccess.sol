// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title GreenLedgerAccess
 * @dev Manages roles and permissions for the GreenLedger platform
 */
contract GreenLedgerAccess is AccessControl, Pausable {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant RETAILER_ROLE = keccak256("RETAILER_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");
    
    // Events
    // event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    // event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event PauseToggled(bool isPaused);
    
    /**
     * @dev Sets up the admin role for the deployer
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev Grants a role to an account
     * @param role The role to grant
     * @param account The account to receive the role
     */
    function grantRole(bytes32 role, address account) 
        public 
        override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        super.grantRole(role, account);
        emit RoleGranted(role, account, msg.sender);
    }
    
    /**
     * @dev Revokes a role from an account
     * @param role The role to revoke
     * @param account The account to revoke the role from
     */
    function revokeRole(bytes32 role, address account) 
        public 
        override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        super.revokeRole(role, account);
        emit RoleRevoked(role, account, msg.sender);
    }
    
    /**
     * @dev Pauses the contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
        emit PauseToggled(true);
    }
    
    /**
     * @dev Unpauses the contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
        emit PauseToggled(false);
    }
    
    /**
     * @dev Checks if an account has a specific role
     * @param role The role to check
     * @param account The account to check
     * @return True if the account has the role
     */
    function hasRole(bytes32 role, address account) 
        public 
        view 
        override 
        returns (bool) 
    {
        return super.hasRole(role, account);
    }
    
    /**
     * @dev Checks if the contract is paused
     * @return True if paused
     */
    function isPaused() external view returns (bool) {
        return paused();
    }
}