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

    
}