// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUserManagement
 * @dev Defines the interface for user role management in GreenLedger.
 */
interface IUserManagement {
    /**
     * @dev Checks if the given account has the specified role.
     * @param role The bytes32 hash of the role to check (e.g., FARMER_ROLE).
     * @param account The address to check for the role.
     * @return True if the account has the role, false otherwise.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);
}