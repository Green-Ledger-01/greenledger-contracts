# GreenLedger Smart Contracts API Reference

## 📋 Overview

GreenLedger consists of two main smart contracts:
- **UserManagement**: Manages user roles (Farmer, Transporter, Buyer)
- **CropBatchToken**: ERC1155 NFT contract for crop batch tokenization

## 🔐 UserManagement Contract

### Constructor
```solidity
constructor(address initialAdmin)
```
Sets up the contract with an initial admin who can manage all roles.

### Constants
```solidity
bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");
```

### Enums
```solidity
enum UserRole {
    Farmer,      // 0
    Transporter, // 1
    Buyer        // 2
}
```

### Core Functions

#### registerUser
```solidity
function registerUser(address _user, UserRole _role) public onlyRole(DEFAULT_ADMIN_ROLE)
```
Assigns a role to a user. Only admins can call this.

**Parameters:**
- `_user`: Address of the user to register
- `_role`: Role to assign (0=Farmer, 1=Transporter, 2=Buyer)

**Events:** Emits `UserRegistered(address indexed user, bytes32 indexed role)`

#### revokeRole
```solidity
function revokeRole(address _user, UserRole _role) public onlyRole(DEFAULT_ADMIN_ROLE)
```
Revokes a role from a user. Only admins can call this.

**Parameters:**
- `_user`: Address of the user
- `_role`: Role to revoke

**Events:** Emits `UserRoleRevoked(address indexed user, bytes32 indexed role)`

#### getUserRolesStatus
```solidity
function getUserRolesStatus(address _user) public view returns (bool isFarmer, bool isTransporter, bool isBuyer)
```
Checks all roles for a user in one call.

**Returns:**
- `isFarmer`: True if user has farmer role
- `isTransporter`: True if user has transporter role
- `isBuyer`: True if user has buyer role

#### pause / unpause
```solidity
function pause() public onlyRole(DEFAULT_ADMIN_ROLE)
function unpause() public onlyRole(DEFAULT_ADMIN_ROLE)
```
Emergency pause/unpause functionality for admins.

### Inherited Functions (from AccessControl)
- `hasRole(bytes32 role, address account)`: Check if account has role
- `grantRole(bytes32 role, address account)`: Grant role (admin only)
- `revokeRole(bytes32 role, address account)`: Revoke role (admin only)

## 🌾 CropBatchToken Contract

### Constructor
```solidity
constructor(
    address _userManagementAddress,
    string memory _initialURI,
    address royaltyRecipient_,
    uint96 royaltyBps_
)
```

**Parameters:**
- `_userManagementAddress`: Address of UserManagement contract
- `_initialURI`: Base URI for metadata
- `royaltyRecipient_`: Address to receive royalties
- `royaltyBps_`: Royalty percentage in basis points (250 = 2.5%)

### Constants
```solidity
bytes32 public constant FARMER_ROLE = keccak256("FARMER_ROLE");
bytes32 public constant ADMIN_ROLE_FOR_CROPS = 0x00;
uint256 public constant MAX_BATCH_SIZE = 100;
```

### Structs
```solidity
struct BatchInfo {
    string cropType;       // e.g., "Wheat", "Coffee"
    uint256 quantity;      // in kg
    string originFarm;     // farm name or ID
    uint256 harvestDate;   // Unix timestamp
    string notes;          // extra details
    string metadataUri;    // IPFS link to JSON metadata
}
```

### Core Functions

#### mintNewBatch
```solidity
function mintNewBatch(
    address _to,
    string memory _cropType,
    uint256 _quantity,
    string memory _originFarm,
    uint256 _harvestDate,
    string memory _notes,
    string memory _metadataUri
) public nonReentrant
```
Mints a new crop batch NFT. Only farmers can call this.

**Parameters:**
- `_to`: Address to mint the token to
- `_cropType`: Type of crop (e.g., "Wheat", "Corn")
- `_quantity`: Quantity in kg (max 100)
- `_originFarm`: Name or ID of the farm
- `_harvestDate`: Unix timestamp of harvest
- `_notes`: Additional notes about the batch
- `_metadataUri`: IPFS URI for metadata (must start with "ipfs://")

**Requirements:**
- Caller must have FARMER_ROLE in UserManagement
- `_to` cannot be zero address
- `_quantity` must be ≤ MAX_BATCH_SIZE (100)
- `_metadataUri` must be valid IPFS URI

**Events:** Emits `CropBatchMinted(uint256 indexed tokenId, address indexed minter, string metadataUri, string cropType, uint256 quantity)`

#### updateTokenUri
```solidity
function updateTokenUri(uint256 id, string memory newUri) public nonReentrant
```
Updates a token's metadata URI if not frozen. Admin only.

**Parameters:**
- `id`: Token ID to update
- `newUri`: New IPFS URI

**Requirements:**
- Caller must have ADMIN_ROLE_FOR_CROPS
- Token must exist
- Metadata must not be frozen
- New URI must be valid IPFS format

**Events:** Emits `MetadataUpdated(uint256 indexed tokenId, string newUri)`

#### freezeMetadata
```solidity
function freezeMetadata(uint256 id) public nonReentrant
```
Permanently locks a token's metadata. Admin only.

**Parameters:**
- `id`: Token ID to freeze

**Requirements:**
- Caller must have ADMIN_ROLE_FOR_CROPS
- Token must exist
- Metadata must not already be frozen

**Events:** Emits `MetadataFrozen(uint256 indexed tokenId)`

#### setRoyaltyInfo
```solidity
function setRoyaltyInfo(address recipient, uint96 bps) external nonReentrant
```
Updates royalty settings. Admin only.

**Parameters:**
- `recipient`: Address to receive royalties
- `bps`: Royalty percentage in basis points (max 10000 = 100%)

**Events:** Emits `RoyaltyInfoUpdated(address indexed recipient, uint96 bps)`

### View Functions

#### batchDetails
```solidity
function batchDetails(uint256 tokenId) public view returns (BatchInfo memory)
```
Returns complete batch information for a token.

#### exists
```solidity
function exists(uint256 id) public view returns (bool)
```
Checks if a token exists.

#### nextTokenId
```solidity
function nextTokenId() public view returns (uint256)
```
Returns the next token ID to be minted.

#### isMetadataFrozen
```solidity
function isMetadataFrozen(uint256 id) public view returns (bool)
```
Checks if a token's metadata is frozen.

#### royaltyInfo
```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256)
```
Returns royalty information per ERC2981 standard.

### Inherited Functions (from ERC1155)
- `balanceOf(address account, uint256 id)`: Get token balance
- `balanceOfBatch(address[] accounts, uint256[] ids)`: Get multiple balances
- `setApprovalForAll(address operator, bool approved)`: Set approval for all tokens
- `isApprovedForAll(address account, address operator)`: Check approval status
- `safeTransferFrom(...)`: Transfer tokens safely
- `safeBatchTransferFrom(...)`: Batch transfer tokens safely

## 🔗 Integration Examples

### JavaScript/Web3.js
```javascript
// Connect to contracts
const userManagement = new web3.eth.Contract(userManagementABI, userManagementAddress);
const cropBatchToken = new web3.eth.Contract(cropBatchTokenABI, cropBatchTokenAddress);

// Register a farmer
await userManagement.methods.registerUser(farmerAddress, 0).send({from: adminAddress});

// Mint a crop batch
await cropBatchToken.methods.mintNewBatch(
    farmerAddress,
    "Wheat",
    50,
    "Green Valley Farm",
    Math.floor(Date.now() / 1000),
    "Organic wheat batch",
    "ipfs://QmYourMetadataHash"
).send({from: farmerAddress});
```

### Ethers.js
```javascript
// Connect to contracts
const userManagement = new ethers.Contract(userManagementAddress, userManagementABI, signer);
const cropBatchToken = new ethers.Contract(cropBatchTokenAddress, cropBatchTokenABI, signer);

// Register a farmer
await userManagement.registerUser(farmerAddress, 0);

// Mint a crop batch
await cropBatchToken.mintNewBatch(
    farmerAddress,
    "Wheat",
    50,
    "Green Valley Farm",
    Math.floor(Date.now() / 1000),
    "Organic wheat batch",
    "ipfs://QmYourMetadataHash"
);
```

## 📝 Events Reference

### UserManagement Events
- `UserRegistered(address indexed user, bytes32 indexed role)`
- `UserRoleRevoked(address indexed user, bytes32 indexed role)`
- `Paused(address account)` (inherited)
- `Unpaused(address account)` (inherited)

### CropBatchToken Events
- `CropBatchMinted(uint256 indexed tokenId, address indexed minter, string metadataUri, string cropType, uint256 quantity)`
- `MetadataUpdated(uint256 indexed tokenId, string newUri)`
- `MetadataFrozen(uint256 indexed tokenId)`
- `RoyaltyInfoUpdated(address indexed recipient, uint96 bps)`
- Standard ERC1155 events (TransferSingle, TransferBatch, etc.)

## ⚠️ Important Notes

1. **IPFS Validation**: All metadata URIs must start with "ipfs://"
2. **Role Dependencies**: CropBatchToken depends on UserManagement for role checks
3. **Batch Size Limit**: Maximum 100kg per crop batch token
4. **Metadata Freezing**: Once frozen, metadata cannot be updated
5. **Reentrancy Protection**: All state-changing functions use nonReentrant modifier
6. **Gas Optimization**: Immutable UserManagement reference saves gas on role checks
