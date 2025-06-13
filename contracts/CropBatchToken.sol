// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./UserManagement.sol";

/**
 * @title CropBatchToken
 * @dev ERC1155 contract for tokenizing unique crop batches as NFTs for GreenLedger
 */
contract CropBatchToken is ERC1155, ReentrancyGuard {
    uint256 public constant MAX_BATCH_SIZE = 100;
    UserManagement public immutable userManagementContract;
    bytes32 public constant ADMIN_ROLE_FOR_CROPS = keccak256("ADMIN_ROLE_FOR_CROPS");

    struct BatchInfo {
        string cropType;
        uint256 quantity;
        string originFarm;
        uint256 harvestDate;
        string notes;
        string metadataUri;
    }

    mapping(uint256 => BatchInfo) public batchDetails;
    mapping(uint256 => bool) private _metadataFrozen;
    uint256 private _nextTokenId = 1;
    address private _royaltyRecipient;
    uint96 private _royaltyBps;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    event CropBatchMinted(uint256 indexed tokenId, address indexed minter, string metadataUri, string cropType, uint256 quantity);
    event MetadataUpdated(uint256 indexed tokenId, string newUri);
    event MetadataFrozen(uint256 indexed tokenId);
    event RoyaltyInfoUpdated(address indexed recipient, uint96 bps);

    constructor(
        address _userManagementAddress,
        string memory _initialURI,
        address royaltyRecipient_,
        uint96 royaltyBps_
    ) ERC1155(_initialURI) {
        require(_userManagementAddress != address(0), "Invalid user management address");
        userManagementContract = UserManagement(_userManagementAddress);
        _setRoyaltyInfo(royaltyRecipient_, royaltyBps_);
    }

    function _setRoyaltyInfo(address recipient, uint96 bps) internal {
        require(bps <= 10000, "Royalty can't exceed 100%");
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
        emit RoyaltyInfoUpdated(recipient, bps);
    }

    function setRoyaltyInfo(address recipient, uint96 bps) external nonReentrant {
        require(userManagementContract.hasRole(userManagementContract.DEFAULT_ADMIN_ROLE(), _msgSender()), "Must be admin");
        _setRoyaltyInfo(recipient, bps);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        require(exists(tokenId), "Token doesn't exist");
        return (_royaltyRecipient, (salePrice * _royaltyBps) / 10000);
    }

    function mintNewBatch(
        address _to,
        string memory _cropType,
        uint256 _quantity,
        string memory _originFarm,
        uint256 _harvestDate,
        string memory _notes,
        string memory _metadataUri
    ) public nonReentrant {
        require(userManagementContract.hasRole(userManagementContract.FARMER_ROLE(), _msgSender()), "Must be farmer");
        require(_to != address(0), "Can't mint to zero address");
        require(_quantity <= MAX_BATCH_SIZE, "Batch too large");
        require(bytes(_metadataUri).length > 0, "Metadata URI required");
        _validateIPFS(_metadataUri);

        uint256 id = _nextTokenId++;
        batchDetails[id] = BatchInfo(_cropType, _quantity, _originFarm, _harvestDate, _notes, _metadataUri);
        _mint(_to, id, 1, "");

        emit CropBatchMinted(id, _msgSender(), _metadataUri, _cropType, _quantity);
    }

    function updateTokenUri(uint256 id, string memory newUri) public nonReentrant {
        require(userManagementContract.hasRole(userManagementContract.DEFAULT_ADMIN_ROLE(), _msgSender()), "Must be admin");
        require(exists(id), "Token doesn't exist");
        require(!_metadataFrozen[id], "Metadata is frozen");
        require(bytes(newUri).length > 0, "New URI required");
        _validateIPFS(newUri);

        batchDetails[id].metadataUri = newUri;
        emit MetadataUpdated(id, newUri);
    }

    function freezeMetadata(uint256 id) public nonReentrant {
        require(userManagementContract.hasRole(userManagementContract.DEFAULT_ADMIN_ROLE(), _msgSender()), "Must be admin");
        require(exists(id), "Token doesn't exist");
        require(!_metadataFrozen[id], "Already frozen");

        _metadataFrozen[id] = true;
        emit MetadataFrozen(id);
    }

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

    function exists(uint256 id) public view returns (bool) {
        return id > 0 && id < _nextTokenId && bytes(batchDetails[id].metadataUri).length > 0;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "Token doesn't exist");
        return batchDetails[tokenId].metadataUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    function isMetadataFrozen(uint256 id) public view returns (bool) {
        return _metadataFrozen[id];
    }
}