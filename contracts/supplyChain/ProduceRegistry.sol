// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../access/GreenLedgerAccess.sol";
import "../tokens/AgriToken.sol";

/**
 * @title ProduceRegistry
 * @dev Registry for agricultural produce in the GreenLedger platform
 */
contract ProduceRegistry is Pausable {
    // Reference to access control contract
    GreenLedgerAccess private _accessControl;
    
    // Reference to AgriToken contract
    AgriToken private _agriToken;
    
    // Produce type struct
    struct ProduceType {
        string name;
        string category;
        string description;
        bool isRegistered;
    }
    
    // Produce certification struct
    struct Certification {
        string name;
        string certifier;
        uint256 issueDate;
        uint256 expiryDate;
        bool isValid;
    }
    
    // Mappings
    mapping(string => ProduceType) private _produceTypes;
    mapping(string => string[]) private _produceCategories;
    mapping(uint256 => Certification[]) private _tokenCertifications;
    mapping(string => uint256[]) private _batchToTokenIds;
    
    // Events
    event ProduceTypeRegistered(string name, string category);
    event ProduceRegistered(uint256 indexed tokenId, string produceType, string batchId);
    event CertificationAdded(uint256 indexed tokenId, string certificationName);
    event CertificationRevoked(uint256 indexed tokenId, string certificationName);
    
    /**
     * @dev Constructor
     * @param accessControlAddress Address of the GreenLedgerAccess contract
     * @param agriTokenAddress Address of the AgriToken contract
     */
    constructor(address accessControlAddress, address agriTokenAddress) {
        require(accessControlAddress != address(0), "Invalid access control address");
        require(agriTokenAddress != address(0), "Invalid token address");
        
        _accessControl = GreenLedgerAccess(accessControlAddress);
        _agriToken = AgriToken(agriTokenAddress);
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
     * @dev Registers a new produce type
     * @param name Name of the produce type
     * @param category Category of the produce
     * @param description Description of the produce type
     */
    function registerProduceType(
        string memory name,
        string memory category,
        string memory description
    ) 
        public 
        onlyRole(_accessControl.ADMIN_ROLE()) 
        whenNotPaused 
    {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(category).length > 0, "Category cannot be empty");
        require(!_produceTypes[name].isRegistered, "Produce type already registered");
        
        _produceTypes[name] = ProduceType({
            name: name,
            category: category,
            description: description,
            isRegistered: true
        });
        
        _produceCategories[category].push(name);
        
        emit ProduceTypeRegistered(name, category);
    }
    
    /**
     * @dev Registers new produce and mints a token
     * @param produceType Type of produce
     * @param quantity Quantity of produce
     * @param location Location of harvest
     * @param batchId Batch ID for the produce
     * @param metadataURI URI for token metadata
     * @return uint256 The ID of the minted token
     */
    function registerProduce(
        string memory produceType,
        uint256 quantity,
        string memory location,
        string memory batchId,
        string memory metadataURI
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        whenNotPaused 
        returns (uint256) 
    {
        require(_produceTypes[produceType].isRegistered, "Produce type not registered");
        require(bytes(batchId).length > 0, "Batch ID cannot be empty");
        require(quantity > 0, "Quantity must be greater than zero");
        
        uint256 harvestDate = block.timestamp;
        
        uint256 tokenId = _agriToken.mintToken(
            msg.sender,
            metadataURI,
            produceType,
            quantity,
            harvestDate,
            location,
            batchId
        );
        
        _batchToTokenIds[batchId].push(tokenId);
        
        emit ProduceRegistered(tokenId, produceType, batchId);
        
        return tokenId;
    }
    
    /**
     * @dev Adds a certification to a token
     * @param tokenId ID of the token
     * @param certificationName Name of the certification
     * @param certifier Name of the certifier
     * @param validityPeriod Validity period in seconds
     */
    function addCertification(
        uint256 tokenId,
        string memory certificationName,
        string memory certifier,
        uint256 validityPeriod
    ) 
        public 
        onlyRole(_accessControl.ADMIN_ROLE()) 
        whenNotPaused 
    {
        require(_agriToken.ownerOf(tokenId) != address(0), "Token does not exist");
        
        uint256 issueDate = block.timestamp;
        uint256 expiryDate = issueDate + validityPeriod;
        
        Certification memory newCertification = Certification({
            name: certificationName,
            certifier: certifier,
            issueDate: issueDate,
            expiryDate: expiryDate,
            isValid: true
        });
        
        _tokenCertifications[tokenId].push(newCertification);
        
        emit CertificationAdded(tokenId, certificationName);
    }
    
    /**
     * @dev Revokes a certification from a token
     * @param tokenId ID of the token
     * @param certificationIndex Index of the certification to revoke
     */
    function revokeCertification(uint256 tokenId, uint256 certificationIndex) 
        public 
        onlyRole(_accessControl.ADMIN_ROLE()) 
        whenNotPaused 
    {
        require(_agriToken.ownerOf(tokenId) != address(0), "Token does not exist");
        require(certificationIndex < _tokenCertifications[tokenId].length, "Certification index out of bounds");
        
        Certification storage certification = _tokenCertifications[tokenId][certificationIndex];
        require(certification.isValid, "Certification already revoked");
        
        certification.isValid = false;
        
        emit CertificationRevoked(tokenId, certification.name);
    }
    
    /**
     * @dev Gets a produce type
     * @param name Name of the produce type
     * @return ProduceType The produce type
     */
    function getProduceType(string memory name) 
        public 
        view 
        returns (ProduceType memory) 
    {
        require(_produceTypes[name].isRegistered, "Produce type not registered");
        return _produceTypes[name];
    }
    
    /**
     * @dev Gets produce types by category
     * @param category Category of produce
     * @return string[] Array of produce type names
     */
    function getProduceTypesByCategory(string memory category) 
        public 
        view 
        returns (string[] memory) 
    {
        return _produceCategories[category];
    }
    
    /**
     * @dev Gets certifications for a token
     * @param tokenId ID of the token
     * @return Certification[] Array of certifications
     */
    function getTokenCertifications(uint256 tokenId) 
        public 
        view 
        returns (Certification[] memory) 
    {
        require(_agriToken.ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenCertifications[tokenId];
    }
    
    /**
     * @dev Gets token IDs by batch ID
     * @param batchId Batch ID
     * @return uint256[] Array of token IDs
     */
    function getTokenIdsByBatch(string memory batchId) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return _batchToTokenIds[batchId];
    }
    
    /**
     * @dev Pauses the contract
     */
    function pause() external onlyRole(_accessControl.ADMIN_ROLE()) {
        _pause();
    }
    
    /**
     * @dev Unpauses the contract
     */
    function unpause() external onlyRole(_accessControl.ADMIN_ROLE()) {
        _unpause();
    }
}

