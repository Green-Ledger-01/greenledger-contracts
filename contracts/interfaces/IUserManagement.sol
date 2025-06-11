// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUserManagement
 * @dev Interface for the UserManagement contract,
 * which handles role-based access control.
 */
interface IUserManagement {
    /**
     * @dev Returns `true` if `account` has `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);
}