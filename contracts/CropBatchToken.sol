// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title CropBatchToken
 * @dev ERC1155 contract for tokenizing unique crop batches as NFTs for GreenLedger.
 * Each token ID represents a unique batch with a supply of 1.
 */
contract CropBatchToken is ERC1155, AccessControl, ReentrancyGuard, Ownable {
    // Role for farmers who can mint tokens
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
    uint256 public constant MAX_BATCH_SIZE = 100;

    // Metadata URIs for each token
    mapping(uint256 => string) private _tokenUris;

    // Track if metadata is frozen
    mapping(uint256 => bool) private _metadataFrozen;

    // Auto-incrementing token ID
    uint256 private _nextTokenId = 1;

    // Royalty information
    address private _royaltyRecipient;
    uint96 private _royaltyBps;

    // ERC2981 interface ID
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Events for tracking
    event CropBatchMinted(uint256 indexed tokenId, address indexed farmer, string metadataUri);
    event MetadataUpdated(uint256 indexed tokenId, string newUri);
    event MetadataFrozen(uint256 indexed tokenId);
    event RoyaltyInfoUpdated(address recipient, uint96 bps);

    constructor(
        address defaultAdmin,
        string memory _initialURI,
        address royaltyRecipient_,
        uint96 royaltyBps_
    ) ERC1155(_initialURI) Ownable(defaultAdmin) { 
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(FARMER_ROLE, defaultAdmin);
        _setRoyaltyInfo(royaltyRecipient_, royaltyBps_);
    }

    /**
     * @dev Sets royalty information for all tokens
     * @param recipient Address to receive royalties
     * @param bps Basis points (1/100 of a percent) for royalty amount
     */
    function _setRoyaltyInfo(address recipient, uint96 bps) internal {
        require(bps <= 10000, "Royalty too high");
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
        emit RoyaltyInfoUpdated(recipient, bps);
    }

    /**
     * @dev Updates royalty information
     * @param recipient Address to receive royalties
     * @param bps Basis points for royalty amount
     */
    function setRoyaltyInfo(address recipient, uint96 bps) external onlyOwner {
        _setRoyaltyInfo(recipient, bps);
    }

    /**
     * @dev ERC2981 royalty info implementation
     */
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (_royaltyRecipient, (salePrice * _royaltyBps) / 10000);
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
     * @dev Allows users to renounce non-admin roles.
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
        return id > 0 && id < _nextTokenId;
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
        override(ERC1155, AccessControl)
        returns (bool) {
            return
                interfaceId == _INTERFACE_ID_ERC2981 ||
                super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev Checks if metadata is frozen for a token.
     * @param id Token ID to check.
     */
    function isMetadataFrozen(uint256 id) public view returns (bool) {
        return _metadataFrozen[id];
    }
}