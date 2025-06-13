// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INonceManager
 * @dev Interface for the ERC-4337 NonceManager contract
 */
interface INonceManager {
    /**
     * @dev Get the nonce for an account and key
     * @param sender The account to get the nonce for
     * @param key The key to get the nonce for
     * @return The nonce for the account and key
     */
    function getNonce(address sender, uint192 key) external view returns (uint256);

    /**
     * @dev Increment the nonce for an account and key
     * @param key The key to increment the nonce for
     */
    function incrementNonce(uint192 key) external;
}

