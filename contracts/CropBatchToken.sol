// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IUserManagement.sol";

/**
 * @title CropBatchToken
 * @dev ERC1155 contract for tokenizing unique crop batches as NFTs for GreenLedger.
 * Each token ID represents a unique batch with a supply of 1.
 */
contract CropBatchToken is ERC1155, ReentrancyGuard {
    // Role for farmers who can mint tokens.
    bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");

    // Admin role for managing contract settings like royalties and metadata freezing.
    bytes32 public constant ADMIN_ROLE_FOR_CROPS = 0x00;

    // Max size for a crop batch (e.g., 100 kg per token).
    uint256 public constant MAX_BATCH_SIZE = 100;

    // Link to UserManagement for role checks.
    IUserManagement public immutable userManagementContract;

    /**
     * @dev Stores all the details for a crop batch, like type, quantity, and origin.
     */
    struct BatchInfo {
        string cropType;       // e.g., "Wheat", "Coffee"
        uint256 quantity;      // in kg
        string originFarm;     // farm name or ID
        uint256 harvestDate;   // Unix timestamp
        string notes;          // extra details
        string metadataUri;    // IPFS link to JSON metadata
    }

    // Tracks details for each batch token.
    mapping(uint256 => BatchInfo) public batchDetails;

    // Flags if a token's metadata is locked.
    mapping(uint256 => bool) private _metadataFrozen;

    // Next available token ID. Starts at 1 and increments.
    uint256 private _nextTokenId = 1;

    address private _royaltyRecipient; 
    uint96 private _royaltyBps;        // Royalty percentage in basis points (e.g., 250 = 2.5%).

    // ERC2981 royalty standard ID.
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Events for off-chain apps to track contract changes.
    event CropBatchMinted(uint256 indexed tokenId, address indexed minter, string metadataUri, string cropType, uint256 quantity);
    event MetadataUpdated(uint256 indexed tokenId, string newUri);
    event MetadataFrozen(uint256 indexed tokenId);
    event RoyaltyInfoUpdated(address indexed recipient, uint96 bps);

    /**
     * @dev Sets up the contract with UserManagement, a base URI, and royalty info.
     */
    constructor(
        address _userManagementAddress,
        string memory _initialURI,
        address royaltyRecipient_,
        uint96 royaltyBps_
    ) ERC1155(_initialURI) {
        require(_userManagementAddress != address(0), "Invalid UserManagement address");
        userManagementContract = IUserManagement(_userManagementAddress);
        _setRoyaltyInfo(royaltyRecipient_, royaltyBps_);
    }

    /**
     * @dev Updates royalty settings with a cap at 100%.
     */
    function _setRoyaltyInfo(address recipient, uint96 bps) internal {
        require(bps <= 10000, "Royalty can't exceed 100%");
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
        emit RoyaltyInfoUpdated(recipient, bps);
    }

    /**
     * @dev Lets admins update royalty recipient and percentage.
     */
    function setRoyaltyInfo(address recipient, uint96 bps) external nonReentrant {
        require(userManagementContract.hasRole(ADMIN_ROLE_FOR_CROPS, _msgSender()), "Must be admin");
        _setRoyaltyInfo(recipient, bps);
    }

    /**
     * @dev Returns royalty info for a sale, per ERC2981.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        require(exists(tokenId), "Token doesn't exist");
        return (_royaltyRecipient, (salePrice * _royaltyBps) / 10000);
    }

    /**
     * @dev Mints a new batch token. Only for farmers.
     */
    function mintNewBatch(
        address _to,
        string memory _cropType,
        uint256 _quantity,
        string memory _originFarm,
        uint256 _harvestDate,
        string memory _notes,
        string memory _metadataUri
    ) public nonReentrant {
        require(userManagementContract.hasRole(FARMER_ROLE, _msgSender()), "Must be farmer");
        require(_to != address(0), "Can't mint to zero address");
        require(_quantity <= MAX_BATCH_SIZE, "Batch too large");
        require(bytes(_metadataUri).length > 0, "Metadata URI required");
        _validateIPFS(_metadataUri);

        uint256 id = _nextTokenId++;
        batchDetails[id] = BatchInfo(_cropType, _quantity, _originFarm, _harvestDate, _notes, _metadataUri);
        _mint(_to, id, 1, "");

        emit CropBatchMinted(id, _msgSender(), _metadataUri, _cropType, _quantity);
    }

    /**
     * @dev Updates a token's metadata URI if not frozen. Admin only.
     */
    function updateTokenUri(uint256 id, string memory newUri) public nonReentrant {
        require(userManagementContract.hasRole(ADMIN_ROLE_FOR_CROPS, _msgSender()), "Must be admin");
        require(exists(id), "Token doesn't exist");
        require(!_metadataFrozen[id], "Metadata is frozen");
        require(bytes(newUri).length > 0, "New URI required");
        _validateIPFS(newUri);

        batchDetails[id].metadataUri = newUri;
        emit MetadataUpdated(id, newUri);
    }

    /**
     * @dev Locks a token's metadata. Admin only.
     */
    function freezeMetadata(uint256 id) public nonReentrant {
        require(userManagementContract.hasRole(ADMIN_ROLE_FOR_CROPS, _msgSender()), "Must be admin");
        require(exists(id), "Token doesn't exist");
        require(!_metadataFrozen[id], "Already frozen");

        _metadataFrozen[id] = true;
        emit MetadataFrozen(id);
    }

    /**
     * @dev Ensures URI starts with "ipfs://".
     */
    function _validateIPFS(string memory uriStr) internal pure {
        bytes memory uriBytes = bytes(uriStr);
        require(uriBytes.length >= 7, "URI too short");
        require(
            uriBytes[0] == 'i' &&
            uriBytes[1] == 'p' &&
            uriBytes[2] == 'f' &&
            uriBytes[3] == 's' &&
            uriBytes[4] == ':' &&
            uriBytes[5] == '/' &&
            uriBytes[6] == '/',
            "Must start with 'ipfs://'"
        );
    }

    /**
     * @dev Checks if a token exists.
     */
    function exists(uint256 id) public view returns (bool) {
        return id > 0 && id < _nextTokenId && bytes(batchDetails[id].metadataUri).length > 0;
    }

    /**
     * @dev Gets a token's metadata URI.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "Token doesn't exist");
        return batchDetails[tokenId].metadataUri;
    }

    /**
     * @dev Confirms interface support (e.g., ERC2981).
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Shows the next token ID to be minted.
     */
    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev Checks if a token's metadata is frozen.
     */
    function isMetadataFrozen(uint256 id) public view returns (bool) {
        return _metadataFrozen[id];
    }
}