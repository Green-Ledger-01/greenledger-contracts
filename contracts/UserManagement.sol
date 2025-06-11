// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol"; 

/**
 * @title UserManagement
 * @dev Manages roles for different participants in the GreenLedger supply chain
 * using OpenZeppelin's AccessControl.
 */
contract UserManagement is AccessControl {
    // These roles are managed by the DEFAULT_ADMIN_ROLE of this contract.
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");

    enum UserRole {
        Farmer,
        Transporter,
        Buyer
    }

    /**
     * @dev Constructor to initialize the contract.
     * The deployer of this contract will automatically be granted the DEFAULT_ADMIN_ROLE,
     * which allows them to grant and revoke other roles (FARMER_ROLE, etc.).
     * @param defaultAdmin The address to grant the initial DEFAULT_ADMIN_ROLE to.
     * Typically, this is the address that deploys the contract.
     */
    constructor(address defaultAdmin) {
        // Grant the deployer (or specified defaultAdmin) the admin role for this contract.
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /**
     * @dev Internal helper function to convert the UserRole enum to its bytes32 constant.
     * @param _role The UserRole enum value.
     * @return The bytes32 representation of the role.
     */
    function _getRoleBytes(UserRole _role) internal pure returns (bytes32) {
        if (_role == UserRole.Farmer) {
            return FARMER_ROLE;
        } else if (_role == UserRole.Transporter) {
            return TRANSPORTER_ROLE;
        } else if (_role == UserRole.Buyer) {
            return BUYER_ROLE;
        }
        revert("UserManagement: Invalid role"); 
    }

    /**
     * @dev Registers a user by granting them a specific role.
     * @param _user The address of the user to register.
     * @param _role The role to assign to the user (Farmer, Transporter, Buyer).
     */
    function registerUser(address _user, UserRole _role) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 roleBytes = _getRoleBytes(_role);
        _grantRole(roleBytes, _user);
    }

    /**
     * @dev Revokes a specific role from a user.
     * Only accounts with the DEFAULT_ADMIN_ROLE (for this contract) can call this function.
     * @param _user The address of the user from whom to revoke the role.
     * @param _role The role to revoke (Farmer, Transporter, Buyer).
     */
    function revokeRole(address _user, UserRole _role) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32 roleBytes = _getRoleBytes(_role);
        _revokeRole(roleBytes, _user);
        // Note: AccessControl automatically emits a RoleRevoked event.
    }

    /**
     * @dev Returns the role status of a user for Farmer, Transporter, and Buyer roles.
     * @param _user The address of the user to check.
     * @return isFarmer True if the user has the FARMER_ROLE.
     * @return isTransporter True if the user has the TRANSPORTER_ROLE.
     * @return isBuyer True if the user has the BUYER_ROLE.
     */
    function getUserRolesStatus(address _user)
        public
        view
        returns (bool isFarmer, bool isTransporter, bool isBuyer)
    {
        isFarmer = hasRole(FARMER_ROLE, _user);
        isTransporter = hasRole(TRANSPORTER_ROLE, _user);
        isBuyer = hasRole(BUYER_ROLE, _user);
    }
}