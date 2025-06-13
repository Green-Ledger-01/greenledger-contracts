// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "../accessControl/GreenLedgerAccess.sol";
import "../tokens/AgriToken.sol";

/**
 * @title SupplyChain
 * @dev Manages the movement of produce through the supply chain with EIP-4337 gasless transaction support
 */
contract SupplyChain is Pausable, ERC2771Context {
    // Reference to access control contract
    GreenLedgerAccess private _accessControl;
    
    // Reference to AgriToken contract
    AgriToken private _agriToken;
    
    // Supply chain state enum
    enum State {
        Harvested,
        Processed,
        Packaged,
        ForSale,
        Sold,
        Shipped,
        Received,
        Purchased
    }
    
    // Supply chain item struct
    struct SupplyChainItem {
        uint256 tokenId;
        State state;
        address producer;
        address distributor;
        address retailer;
        address consumer;
        uint256[] timestamps;
        string[] locations;
        string[] notes;
    }
    
    // Mappings
    mapping(uint256 => SupplyChainItem) private _supplyChainItems;
    mapping(address => uint256[]) private _producerItems;
    mapping(address => uint256[]) private _distributorItems;
    mapping(address => uint256[]) private _retailerItems;
    mapping(address => uint256[]) private _consumerItems;
    
    // Events
    event Harvested(uint256 indexed tokenId, address indexed producer, string location);
    event Processed(uint256 indexed tokenId, address indexed producer, string location);
    event Packaged(uint256 indexed tokenId, address indexed producer, string location);
    event ForSale(uint256 indexed tokenId, address indexed producer);
    event Sold(uint256 indexed tokenId, address indexed producer, address indexed distributor);
    event Shipped(uint256 indexed tokenId, address indexed distributor, string location);
    event Received(uint256 indexed tokenId, address indexed retailer, string location);
    event Purchased(uint256 indexed tokenId, address indexed consumer);
    
    /**
     * @dev Constructor
     * @param accessControlAddress Address of the GreenLedgerAccess contract
     * @param agriTokenAddress Address of the AgriToken contract
     * @param trustedForwarder Address of the trusted forwarder for meta-transactions
     */
    constructor(
        address accessControlAddress, 
        address agriTokenAddress,
        address trustedForwarder
    ) ERC2771Context(trustedForwarder) {
        require(accessControlAddress != address(0), "Invalid access control address");
        require(agriTokenAddress != address(0), "Invalid token address");
        require(trustedForwarder != address(0), "Invalid trusted forwarder address");
        
        _accessControl = GreenLedgerAccess(accessControlAddress);
        _agriToken = AgriToken(agriTokenAddress);
    }
    
    /**
     * @dev Override _msgSender to support both regular and meta-transactions
     */
    function _msgSender() internal view override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }
    
    /**
     * @dev Override _msgData to support both regular and meta-transactions
     */
    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
    
    /**
     * @dev Modifier to check if the caller has a specific role
     * @param role The role to check
     */
    modifier onlyRole(bytes32 role) {
        require(_accessControl.hasRole(role, _msgSender()), "Caller does not have the required role");
        _;
    }
    
    /**
     * @dev Modifier to verify caller is token owner
     * @param tokenId ID of the token
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        require(_agriToken.ownerOf(tokenId) == _msgSender(), "Caller is not token owner");
        _;
    }
    
    /**
     * @dev Modifier to verify state transition
     * @param tokenId ID of the token
     * @param expectedState Expected current state
     */
    modifier verifyState(uint256 tokenId, State expectedState) {
        require(_supplyChainItems[tokenId].state == expectedState, "Invalid item state");
        _;
    }
    
    /**
     * @dev Initializes a supply chain item after harvest
     * @param tokenId ID of the token
     * @param location Location of harvest
     * @param note Additional note
     */
    function harvestItem(
        uint256 tokenId,
        string memory location,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        onlyTokenOwner(tokenId) 
        whenNotPaused 
    {
        require(_supplyChainItems[tokenId].tokenId == 0, "Item already in supply chain");
        
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;
        
        string[] memory locations = new string[](1);
        locations[0] = location;
        
        string[] memory notes = new string[](1);
        notes[0] = note;
        
        _supplyChainItems[tokenId] = SupplyChainItem({
            tokenId: tokenId,
            state: State.Harvested,
            producer: _msgSender(),
            distributor: address(0),
            retailer: address(0),
            consumer: address(0),
            timestamps: timestamps,
            locations: locations,
            notes: notes
        });
        
        _producerItems[_msgSender()].push(tokenId);
        
        emit Harvested(tokenId, _msgSender(), location);
    }
    
    /**
     * @dev Processes an item
     * @param tokenId ID of the token
     * @param location Location of processing
     * @param note Additional note
     */
    function processItem(
        uint256 tokenId,
        string memory location,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.Harvested) 
        whenNotPaused 
    {
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        
        item.state = State.Processed;
        item.timestamps.push(block.timestamp);
        item.locations.push(location);
        item.notes.push(note);
        
        emit Processed(tokenId, _msgSender(), location);
    }
    
    /**
     * @dev Packages an item
     * @param tokenId ID of the token
     * @param location Location of packaging
     * @param note Additional note
     */
    function packageItem(
        uint256 tokenId,
        string memory location,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.Processed) 
        whenNotPaused 
    {
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        
        item.state = State.Packaged;
        item.timestamps.push(block.timestamp);
        item.locations.push(location);
        item.notes.push(note);
        
        emit Packaged(tokenId, _msgSender(), location);
    }
    
    /**
     * @dev Lists an item for sale
     * @param tokenId ID of the token
     * @param note Additional note
     */
    function listItemForSale(
        uint256 tokenId,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.Packaged) 
        whenNotPaused 
    {
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        
        item.state = State.ForSale;
        item.timestamps.push(block.timestamp);
        item.notes.push(note);
        
        emit ForSale(tokenId, _msgSender());
    }
    
    /**
     * @dev Sells an item to a distributor
     * @param tokenId ID of the token
     * @param distributor Address of the distributor
     * @param note Additional note
     */
    function sellItem(
        uint256 tokenId,
        address distributor,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.FARMER_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.ForSale) 
        whenNotPaused 
    {
        require(distributor != address(0), "Invalid distributor address");
        require(_accessControl.hasRole(_accessControl.DISTRIBUTOR_ROLE(), distributor), "Address is not a distributor");
        
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        
        item.state = State.Sold;
        item.distributor = distributor;
        item.timestamps.push(block.timestamp);
        item.notes.push(note);
        
        _distributorItems[distributor].push(tokenId);
        
        // Note: This doesn't transfer the token, just updates the state
        // Token transfer should be handled by the marketplace contract
        
        emit Sold(tokenId, _msgSender(), distributor);
    }
    
    /**
     * @dev Ships an item
     * @param tokenId ID of the token
     * @param location Location of shipping
     * @param note Additional note
     */
    function shipItem(
        uint256 tokenId,
        string memory location,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.DISTRIBUTOR_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.Sold) 
        whenNotPaused 
    {
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        require(item.distributor == _msgSender(), "Caller is not the assigned distributor");
        
        item.state = State.Shipped;
        item.timestamps.push(block.timestamp);
        item.locations.push(location);
        item.notes.push(note);
        
        emit Shipped(tokenId, _msgSender(), location);
    }
    
    /**
     * @dev Receives an item
     * @param tokenId ID of the token
     * @param location Location of receipt
     * @param note Additional note
     */
    function receiveItem(
        uint256 tokenId,
        string memory location,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.RETAILER_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.Shipped) 
        whenNotPaused 
    {
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        
        item.state = State.Received;
        item.retailer = _msgSender();
        item.timestamps.push(block.timestamp);
        item.locations.push(location);
        item.notes.push(note);
        
        _retailerItems[_msgSender()].push(tokenId);
        
        emit Received(tokenId, _msgSender(), location);
    }
    
    /**
     * @dev Purchases an item
     * @param tokenId ID of the token
     * @param note Additional note
     */
    function purchaseItem(
        uint256 tokenId,
        string memory note
    ) 
        public 
        onlyRole(_accessControl.CONSUMER_ROLE()) 
        onlyTokenOwner(tokenId) 
        verifyState(tokenId, State.Received) 
        whenNotPaused 
    {
        SupplyChainItem storage item = _supplyChainItems[tokenId];
        
        item.state = State.Purchased;
        item.consumer = _msgSender();
        item.timestamps.push(block.timestamp);
        item.notes.push(note);
        
        _consumerItems[_msgSender()].push(tokenId);
        
        emit Purchased(tokenId, _msgSender());
    }
    
    /**
     * @dev Gets a supply chain item
     * @param tokenId ID of the token
     * @return SupplyChainItem The supply chain item
     */
    function getSupplyChainItem(uint256 tokenId) 
        public 
        view 
        returns (SupplyChainItem memory) 
    {
        require(_supplyChainItems[tokenId].tokenId != 0, "Item not in supply chain");
        return _supplyChainItems[tokenId];
    }
    
    /**
     * @dev Gets items by producer
     * @param producer Address of the producer
     * @return uint256[] Array of token IDs
     */
    function getItemsByProducer(address producer) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return _producerItems[producer];
    }
    
    /**
     * @dev Gets items by distributor
     * @param distributor Address of the distributor
     * @return uint256[] Array of token IDs
     */
    function getItemsByDistributor(address distributor) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return _distributorItems[distributor];
    }
    
    /**
     * @dev Gets items by retailer
     * @param retailer Address of the retailer
     * @return uint256[] Array of token IDs
     */
    function getItemsByRetailer(address retailer) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return _retailerItems[retailer];
    }
    
    /**
     * @dev Gets items by consumer
     * @param consumer Address of the consumer
     * @return uint256[] Array of token IDs
     */
    function getItemsByConsumer(address consumer) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return _consumerItems[consumer];
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