// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStakeManager
 * @dev Interface for the ERC-4337 StakeManager contract
 */
interface IStakeManager {
    /**
     * @dev Emitted when a stake is deposited
     */
    event Deposited(
        address indexed account,
        uint256 totalDeposit
    );

    /**
     * @dev Emitted when a stake is withdrawn
     */
    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @dev Emitted when a stake is added
     */
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 unstakeDelaySec
    );

    /**
     * @dev Emitted when a stake is unlocked
     */
    event StakeUnlocked(
        address indexed account,
        uint256 withdrawTime
    );

    /**
     * @dev Emitted when a stake is withdrawn
     */
    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @dev Get the deposit info for an account
     * @param account The account to get the deposit info for
     * @return deposit The deposit amount
     * @return staked Whether the account is staked
     * @return stake The stake amount
     * @return unstakeDelaySec The unstake delay in seconds
     * @return withdrawTime The withdraw time
     */
    function getDepositInfo(address account) external view returns (
        uint256 deposit,
        bool staked,
        uint256 stake,
        uint256 unstakeDelaySec,
        uint256 withdrawTime
    );

    /**
     * @dev Get the balance of an account
     * @param account The account to get the balance for
     * @return The balance of the account
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Add a deposit for an account
     * @param account The account to add the deposit for
     */
    function depositTo(address account) external payable;

    /**
     * @dev Add a stake for an account
     * @param unstakeDelaySec The unstake delay in seconds
     */
    function addStake(uint32 unstakeDelaySec) external payable;

    /**
     * @dev Unlock the stake for an account
     */
    function unlockStake() external;

    /**
     * @dev Withdraw the stake for an account
     * @param withdrawAddress The address to withdraw to
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * @dev Withdraw from an account
     * @param withdrawAddress The address to withdraw to
     * @param withdrawAmount The amount to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

