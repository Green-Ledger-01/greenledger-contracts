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

    // Events for tracking
    event CropBatchMinted(uint256 indexed tokenId, address indexed farmer, string metadataUri);
    event MetadataUpdated(uint256 indexed tokenId, string newUri);
    event MetadataFrozen(uint256 indexed tokenId);

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155Base(_defaultAdmin, _name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(FARMER_ROLE, _defaultAdmin);  // -> For initial testing
    }

    /**
     * @dev Mints a new crop batch NFT with an auto-incrementing ID.
     * @param metadataUri IPFS URI for the token's metadata.
     * @param data Additional data for the mint.
     */
    function mint(string memory metadataUri, bytes memory data) public nonReentrant {
        require(hasRole(FARMER_ROLE, msg.sender), "Caller must be a farmer");
        require(bytes(metadataUri).lenght > 0, "Metadata URI cannot be empty");
        _validateIPFS(metadataUri);

        uint256 id = _nextTokenId++;
        _tokenUris[id] = metadataUri;
        _mint(msg.sender, id, 1, data);

        emit CropBatchMinted(id, msg.sender, metadataUri);
    }

    /**
     * @dev Batch mints multiple NFTs with auto-incrementing IDs.
     * @param metadataUris Array of IPFS URIs for the tokens' metadata.
     * @param data Additional data for the mint.
     */
    function batchMint(string[] memory metadataUris, bytes memory data) public nonReentrant {
        require(hasRole(FARMER_ROLE, msg.sender), "Caller must be a farmer");
        require(metadataUris.length > 0, "No metadata URIs provided");

        uint256[] memory ids = new uint256[](metadataUris.length);
        uint256[] memory amounts = new uint256[](metadataUris.length);

        for (uint256 i = 0; i < metadataUris.lenth; i++) {
            require(bytes(metadataUris[i]).length > 0, "Metadata URI cannot be empty");
            _validateIPFS(metadataUri[i]);

            uint256 id = _nextTokenId++;
            _tokenUris[id] = metadataUris[i];
            ids[i] = id;
            amounts[i] = 1;
        }

        _mintBatch(msg.sender, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            emit CropBatchMinted(ids[i], msg.sender, metadataUris[i]);
        }
    }

}