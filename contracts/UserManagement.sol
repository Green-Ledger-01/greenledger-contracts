// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title UserManagement
 * @dev Manages user roles (Farmer, Transporter, Buyer) for GreenLedger.
 * Built with AccessControl for role management and Pausable for emergencies.
 */
contract UserManagement is AccessControl, Pausable {
    // Roles for supply chain folks.
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");

    // Enum to make roles easier to work with.
    enum UserRole {
        Farmer,
        Transporter,
        Buyer
    }

    // Events to track role changes.
    event UserRegistered(address indexed user, bytes32 indexed role);
    event UserRoleRevoked(address indexed user, bytes32 indexed role);

    /**
     * @dev Sets up the contract with an admin who can manage roles.
     */
    constructor(address initialAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    }

    /**
     * @dev Converts UserRole enum to bytes32 role hash.
     */
    function _getRoleBytes(UserRole _role) internal pure returns (bytes32) {
        if (_role == UserRole.Farmer) return FARMER_ROLE;
        if (_role == UserRole.Transporter) return TRANSPORTER_ROLE;
        if (_role == UserRole.Buyer) return BUYER_ROLE;
        revert("Invalid role");
    }

    /**
     * @dev Assigns a role to a user. Only admins can call this.
     */
    function registerUser(address _user, UserRole _role) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_user != address(0), "Can't register zero address");
        bytes32 roleBytes = _getRoleBytes(_role);
        _grantRole(roleBytes, _user);
        emit UserRegistered(_user, roleBytes);
    }

    /**
     * @dev Revokes a role from a user. Only admins can call this.
     */
    function revokeRole(address _user, UserRole _role) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_user != address(0), "Can't revoke from zero address");
        bytes32 roleBytes = _getRoleBytes(_role);
        _revokeRole(roleBytes, _user);
        emit UserRoleRevoked(_user, roleBytes);
    }

    /**
     * @dev Checks a user's roles in one go.
     */
    function getUserRolesStatus(address _user)
        public
        view
        returns (
            bool isFarmer,
            bool isTransporter,
            bool isBuyer
        )
    {
        isFarmer = hasRole(FARMER_ROLE, _user);
        isTransporter = hasRole(TRANSPORTER_ROLE, _user);
        isBuyer = hasRole(BUYER_ROLE, _user);
    }

    /**
     * @dev Pauses the contract in emergencies. Admin-only.
     */
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Admin-only.
     */
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Confirms support for AccessControl interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}