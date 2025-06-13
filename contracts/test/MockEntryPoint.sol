// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockEntryPoint
 * @dev Mock implementation of the EntryPoint contract for testing
 */
contract MockEntryPoint {
    mapping(address => uint256) private _balances;
    
    /**
     * @dev Get the balance of an account
     * @param account The account to get the balance for
     * @return The balance of the account
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account] > 0 ? _balances[account] : 1 ether;
    }
    
    /**
     * @dev Add a deposit for an account
     * @param account The account to add the deposit for
     */
    function depositTo(address account) external payable {
        _balances[account] += msg.value;
    }
    
    /**
     * @dev Withdraw from an account
     * @param withdrawAddress The address to withdraw to
     * @param withdrawAmount The amount to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external {
        // No actual withdrawal in the mock
    }
    
    /**
     * @dev Add a stake for an account
     * @param unstakeDelaySec The unstake delay in seconds
     */
    function addStake(uint32 unstakeDelaySec) external payable {
        // No actual staking in the mock
    }
    
    /**
     * @dev Unlock the stake for an account
     */
    function unlockStake() external {
        // No actual unlocking in the mock
    }
    
    /**
     * @dev Withdraw the stake for an account
     * @param withdrawAddress The address to withdraw to
     */
    function withdrawStake(address payable withdrawAddress) external {
        // No actual withdrawal in the mock
    }
}

