// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title CropBatchToken
 * @dev ERC1155 contract for tokenizing unique crop batches as NFTs for GreenLedger.
 * Each token ID represents a unique batch with a supply of 1.
 */
contract CropBatchToken is ERC1155, AccessControl, ReentrancyGuard, ERC2981 {
    // Role for farmers who can mint tokens
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    uint256 public constant MAX_BATCH_SIZE = 100;

    // Metadata URIs for each token 
    mapping(uint256 => string) private _tokenUris;

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
        string memory _uri,
        address _royaltyRecipient,
        uint96 _royaltyBps
    ) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setDefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /**
     * @dev Mints a new crop batch NFT with an auto-incrementing ID.
     * @param metadataUri IPFS URI for the token's metadata.
     * @param data Additional data for the mint.
     */
    function mint(string memory metadataUri, bytes memory data) public nonReentrant {
        require(hasRole(FARMER_ROLE, msg.sender), "Caller must be a farmer");
        require(bytes(metadataUri).length > 0, "Metadata URI cannot be empty");
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
        require(metadataUris.length <= MAX_BATCH_SIZE, "Batch size exceeds limit");

        uint256[] memory ids = new uint256[](metadataUris.length);
        uint256[] memory amounts = new uint256[](metadataUris.length);

        for (uint256 i = 0; i < metadataUris.length; i++) {
            require(bytes(metadataUris[i]).length > 0, "Metadata URI cannot be empty");
            _validateIPFS(metadataUris[i]);

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

    /**
     * @dev Updates the metadata URI for a token if not frozen.
     * @param id Token ID to update.
     * @param newUri New IPFS URI.
     */
    function updateTokenUri(uint256 id, string memory newUri) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can update URI");
        require(exists(id), "Token does not exist");
        require(!_metadataFrozen[id], "Metadata is frozen");
        _validateIPFS(newUri);

        _tokenUris[id] = newUri;
        emit MetadataUpdated(id, newUri);
    }

    /**
     * @dev Freezes the metadata for a token, making it immutable.
     * @param id Token ID to freeze.
     */
    function freezeMetadata(uint256 id) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can freeze metadata");
        require(exists(id), "Token does not exist");
        require(!_metadataFrozen[id], "Metadata already frozen");

        _metadataFrozen[id] = true;
        emit MetadataFrozen(id);
    }

    /**
     * @dev Grants the farmer role to an account.
     * @param account Address to grant the role to.
     */
    function grantFarmerRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can grant roles");
        _grantRole(FARMER_ROLE, account);
    }

    /**
     * @dev Revokes the farmer role from an account.
     * @param account Address to revoke the role from.
     */
    function revokeFarmerRole(address account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can revoke roles");
        _revokeRole(FARMER_ROLE, account);
    }

     /**
     * @dev Allows users to renounse non-admin roles.
     * @param role Role to renounce.
     * @param account Account renouncing the role.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == msg.sender, "Can only renounce roles for self");
        require(role != DEFAULT_ADMIN_ROLE, "Cannot renounce admin role");
        super.renounceRole(role, account);
    }

    /**
     * @dev Validates that a URI starts with "ipfs://".
     * @param uriStr URI to validate.
     */
    function _validateIPFS(string memory uriStr) internal pure {
        bytes memory uriBytes = bytes(uriStr);
        require(uriBytes.length >= 7, "Invalid URI length");
        require(
            uriBytes[0] == 'i' &&
            uriBytes[1] == 'p' &&
            uriBytes[2] == 'f' &&
            uriBytes[3] == 's' &&
            uriBytes[4] == ':' &&
            uriBytes[5] == '/' &&
            uriBytes[6] == '/',
            "URI must start with 'ipfs://'"
        );
    }

    /**
     * @dev Checks if a token exists.
     * @param id Token ID to check.
     */
    function exists(uint256 id) public view returns (bool) {
        return _nextTokenId > id;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param tokenId Token ID to get URI for.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "Token does not exist");
        return _tokenUris[tokenId];
    }

    /**
     * @dev Supports ERC165 interface detection.
     * @param interfaceId interface ID to check.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, ERC2981)
        returns (bool) {
            return super.supportsInterface(interfaceId);
        }
}