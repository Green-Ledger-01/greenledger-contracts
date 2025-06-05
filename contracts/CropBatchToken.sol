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
    
}