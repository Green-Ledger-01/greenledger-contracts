// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title CropBatchToken
 * @dev ERC1155 contract for tokenizing for tokenizing unique crop batches as NFTs for GreenLedger.
 * Each token ID represents a unique batch with a supply of 1.
 */ 
contract CropBatchToken is ERC1155Base, PermissionsEnumerable, ReentrancyGuard {
    // Role for farmers who can mint tokens
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");

    // Metadata URIs for each token 
    mapping(uint256 => string) private _tokensUris;

    // Track if metadata is frozen
    mapping(uint256 => bool) private _metadataFrozen;

    // Auto-incrementing token ID
    uint256 private _nextTokenId = 1;

    
}