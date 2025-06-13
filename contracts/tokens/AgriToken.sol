// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../accessControl/GreenLedgerAccess.sol";

/**
 * @title AgriToken
 * @dev ERC721 token for representing agricultural produce in the GreenLedger platform
 */
contract AgriToken is ERC721URIStorage, ERC721Enumerable, Pausable {
    using Counters for Counters.Counter;
    
    // Token ID counter
    Counters.Counter private _tokenIdCounter;
    
    // Reference to access control contract
    GreenLedgerAccess private _accessControl;
    
    // Mapping from token ID to produce data
    struct ProduceData {
        string produceType;
        uint256 quantity;
        uint256 harvestDate;
        string location;
        string batchId;
        address farmer;
    }
    
    mapping(uint256 => ProduceData) private _produceData;
    
    // Events
    event TokenMinted(uint256 indexed tokenId, address indexed to, string produceType, string batchId);
    event TokenBurned(uint256 indexed tokenId);
    event MetadataUpdated(uint256 indexed tokenId, string newUri);
    
    /**
     * @dev Constructor
     * @param accessControlAddress Address of the GreenLedgerAccess contract
     */
    constructor(address accessControlAddress) ERC721("GreenLedger Agricultural Token", "AGRI") {
        require(accessControlAddress != address(0), "Invalid access control address");
        _accessControl = GreenLedgerAccess(accessControlAddress);
    }
    
    /**
     * @dev Modifier to check if the caller has a specific role
     * @param role The role to check
     */
    modifier onlyRole(bytes32 role) {
        require(_accessControl.hasRole(role, msg.sender), "Caller does not have the required role");
        _;
    }
    
    /**
     * @dev Mints a new token
     * @param to Address to mint the token to
     * @param uri Token URI for metadata
     * @param produceType Type of produce
     * @param quantity Quantity of produce
     * @param harvestDate Date of harvest
     * @param location Location of harvest
     * @param batchId Batch ID for the produce
     * @return uint256 The ID of the minted token
     */
    function mintToken(
        address to,
        string memory uri,
        string memory produceType,
        uint256 quantity,
        uint256 harvestDate,
        string memory location,
        string memory batchId
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        whenNotPaused 
        returns (uint256) 
    {
        require(to != address(0), "Cannot mint to zero address");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        _produceData[tokenId] = ProduceData({
            produceType: produceType,
            quantity: quantity,
            harvestDate: harvestDate,
            location: location,
            batchId: batchId,
            farmer: msg.sender
        });
        
        emit TokenMinted(tokenId, to, produceType, batchId);
        
        return tokenId;
    }
    
    /**
     * @dev Burns a token
     * @param tokenId ID of the token to burn
     */
    function burnToken(uint256 tokenId) 
        public 
        whenNotPaused 
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        
        _burn(tokenId);
        delete _produceData[tokenId];
        
        emit TokenBurned(tokenId);
    }
    
    /**
     * @dev Updates token metadata
     * @param tokenId ID of the token to update
     * @param newUri New token URI
     */
    function updateTokenURI(uint256 tokenId, string memory newUri) 
        public 
        onlyRole(_accessControl.ADMIN_ROLE()) 
        whenNotPaused 
    {
        require(_exists(tokenId), "Token does not exist");
        
        _setTokenURI(tokenId, newUri);
        
        emit MetadataUpdated(tokenId, newUri);
    }
    
    /**
     * @dev Gets produce data for a token
     * @param tokenId ID of the token
     * @return ProduceData Produce data for the token
     */
    function getProduceData(uint256 tokenId) 
        public 
        view 
        returns (ProduceData memory) 
    {
        require(_exists(tokenId), "Token does not exist");
        return _produceData[tokenId];
    }
    
    /**
     * @dev Pauses token transfers and minting
     */
    function pause() external onlyRole(_accessControl.ADMIN_ROLE()) {
        _pause();
    }
    
    /**
     * @dev Unpauses token transfers and minting
     */
    function unpause() external onlyRole(_accessControl.ADMIN_ROLE()) {
        _unpause();
    }
    
    /**
     * @dev Hook that is called before any token transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    /**
     * @dev Required override for ERC721URIStorage and ERC721Enumerable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Required override for ERC721URIStorage and ERC721Enumerable
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    /**
     * @dev Required override for ERC721URIStorage and ERC721Enumerable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}

