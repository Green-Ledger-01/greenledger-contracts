# GreenLedger Smart Contracts

This repository contains the smart contracts for GreenLedger, a blockchain-based platform for tokenizing and tracking crop batches as NFTs on the Lisk blockchain.

## 🌱 Overview

GreenLedger enables farmers to mint unique NFTs representing their crop batches, providing transparency and traceability in the agricultural supply chain. Each NFT contains metadata about the crop batch, including farming practices, location, and quality metrics.

## 📋 Deployment Information

### 🚀 Live Contract (Lisk Sepolia Testnet)

- **Contract Address**: `0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C`
- **Network**: Lisk Sepolia Testnet
- **Transaction Hash**: `0x1b37553ff2727ed4c639acbd220c94976193c55f0d578bcecbb8f50354705d8c`
- **Deployer**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`
- **Block Explorer**: [View on Lisk Sepolia Explorer](https://sepolia-blockscout.lisk.com/address/0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C)

### ⚙️ Contract Configuration

- **Base URI**: `https://api.greenledger.com/metadata/{id}`
- **Royalty Rate**: 2.5% (250 basis points)
- **Royalty Recipient**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`
- **Max Batch Size**: 100 tokens per transaction
- **Solidity Version**: 0.8.20

## 📄 Contracts

### CropBatchToken.sol

An ERC1155-based smart contract that allows farmers to mint unique crop batch NFTs. Key features include:

- **🔐 Role-based Access Control**: Only authorized farmers can mint tokens
- **📁 IPFS Metadata**: All metadata is stored on IPFS for decentralization
- **✏️ Metadata Management**: Admins can update metadata before it's frozen
- **💰 Royalty Support**: ERC2981 compliant royalty system
- **⚡ Batch Operations**: Support for minting multiple tokens in a single transaction
- **🔒 Security**: Reentrancy protection and comprehensive access controls
- **🧊 Metadata Freezing**: Ability to make metadata immutable

## 🚀 Getting Started

### Prerequisites

- Node.js (v14 or higher) - **Note**: Tested with Node.js v22.16.0
- npm or yarn
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd greenledger-contracts
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file:
```bash
cp .env.example .env
```

4. Configure your environment variables in `.env`:
```env
# Your private key (keep this secret!)
PRIVATE_KEY=your_private_key_here

# Lisk Sepolia testnet RPC URL
LISK_SEPOLIA_RPC_URL=https://rpc.sepolia.lisk.com

# Optional: Gas settings
GAS_PRICE=20000000000
GAS_LIMIT=6721975
```

### Compilation

Compile the smart contracts:
```bash
npm run compile
# or
npx hardhat compile
```

### Testing

Run the test suite:
```bash
npm test
# or
npx hardhat test
```

### Deployment

Deploy to Lisk Sepolia testnet:
```bash
npm run deploy
# or
npx hardhat run scripts/deploy.js --network lisk
```

## 🏗️ Contract Architecture

### 👥 Roles

- **DEFAULT_ADMIN_ROLE** (`0x00`):
  - Can manage all roles
  - Update metadata URIs
  - Freeze metadata
  - Set royalty information

- **FARMER_ROLE** (`keccak256("FARMER_ROLE")`):
  - Can mint crop batch tokens
  - Can batch mint multiple tokens

### 🔧 Key Functions

#### Minting Functions
- `mint(metadataUri, data)`: Mint a single crop batch NFT
- `batchMint(metadataUris, data)`: Mint multiple NFTs in one transaction (max 100)

#### Metadata Management
- `updateTokenUri(id, newUri)`: Update metadata URI (admin only, before freezing)
- `freezeMetadata(id)`: Make metadata immutable (admin only)
- `isMetadataFrozen(id)`: Check if metadata is frozen

#### Role Management
- `grantFarmerRole(account)`: Grant farmer role to an address
- `revokeFarmerRole(account)`: Revoke farmer role from an address
- `hasRole(role, account)`: Check if account has specific role

#### View Functions
- `uri(tokenId)`: Get metadata URI for a token
- `exists(tokenId)`: Check if token exists
- `nextTokenId()`: Get the next token ID to be minted
- `royaltyInfo(tokenId, salePrice)`: Get royalty information (ERC2981)

#### Royalty Functions
- `setRoyaltyInfo(recipient, bps)`: Update royalty settings (owner only)
- `royaltyInfo(tokenId, salePrice)`: Get royalty amount and recipient

## 📊 Contract Interaction Examples

### Using Ethers.js

```javascript
const { ethers } = require('ethers');

// Contract details
const contractAddress = '0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C';
const abi = [...]; // Use the ABI from artifacts/contracts/CropBatchToken.sol/CropBatchToken.json

// Connect to Lisk Sepolia
const provider = new ethers.providers.JsonRpcProvider('https://rpc.sepolia.lisk.com');
const wallet = new ethers.Wallet('YOUR_PRIVATE_KEY', provider);
const contract = new ethers.Contract(contractAddress, abi, wallet);

// Grant farmer role
await contract.grantFarmerRole('0xFarmerAddress');

// Mint a token
await contract.mint('ipfs://QmYourMetadataHash', '0x');

// Batch mint tokens
await contract.batchMint([
  'ipfs://QmHash1',
  'ipfs://QmHash2',
  'ipfs://QmHash3'
], '0x');

// Update metadata (before freezing)
await contract.updateTokenUri(1, 'ipfs://QmNewMetadataHash');

// Freeze metadata
await contract.freezeMetadata(1);
```

### Using Hardhat Console

```bash
npx hardhat console --network lisk
```

```javascript
const contract = await ethers.getContractAt('CropBatchToken', '0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C');

// Check contract info
await contract.nextTokenId();
await contract.owner();

// Mint a token
await contract.mint('ipfs://QmSampleHash', '0x');
```

## 📋 Metadata Structure

Crop batch metadata should follow this structure and be stored on IPFS:

```json
{
  "name": "Organic Tomatoes Batch #001",
  "description": "Premium organic tomatoes grown using sustainable farming practices",
  "image": "ipfs://QmImageHash",
  "external_url": "https://greenledger.com/batch/001",
  "attributes": [
    {
      "trait_type": "Crop Type",
      "value": "Tomatoes"
    },
    {
      "trait_type": "Farming Method",
      "value": "Organic"
    },
    {
      "trait_type": "Harvest Date",
      "value": "2024-01-15"
    },
    {
      "trait_type": "Location",
      "value": "Farm A, Region B"
    },
    {
      "trait_type": "Batch Size",
      "value": "500 kg"
    },
    {
      "trait_type": "Quality Grade",
      "value": "Premium"
    },
    {
      "trait_type": "Certification",
      "value": "USDA Organic"
    }
  ],
  "properties": {
    "farmer": "0xFarmerAddress",
    "farm_id": "FARM_001",
    "batch_id": "BATCH_001",
    "harvest_timestamp": 1705276800,
    "coordinates": {
      "latitude": 40.7128,
      "longitude": -74.0060
    }
  }
}
```

## 🔒 Security Considerations

- **IPFS Validation**: All metadata URIs must start with "ipfs://" for decentralization
- **Metadata Freezing**: Metadata can be updated by admins until it's frozen
- **Role Management**: Role management is restricted to admin accounts
- **Reentrancy Protection**: Implemented for all state-changing functions
- **Access Control**: Comprehensive role-based access control system
- **Input Validation**: All inputs are validated before processing

## 🧪 Testing

The contract includes comprehensive tests covering:

- Role management functionality
- Minting operations (single and batch)
- Metadata management and freezing
- Access control enforcement
- IPFS URI validation
- Royalty functionality
- Edge cases and error conditions

Run tests with:
```bash
npm test
```

## 📁 Project Structure

```
greenledger-contracts/
├── contracts/
│   ├── CropBatchToken.sol          # Main ERC1155 contract
│   └── SimpleCropBatchToken.sol    # Simplified version (for testing)
├── scripts/
│   ├── deploy.js                   # Main deployment script
│   └── deploy-simple.js           # Alternative deployment script
├── test/
│   ├── CropBatchToken.test.js     # Comprehensive test suite
│   └── SimpleCropBatchToken.test.js # Tests for simplified version
├── artifacts/                      # Compiled contract artifacts
├── .env                           # Environment variables (not committed)
├── .env.example                   # Environment template
├── hardhat.config.js              # Hardhat configuration
├── package.json                   # Dependencies and scripts
└── README.md                      # This file
```

## 🌐 Network Information

### Lisk Sepolia Testnet
- **RPC URL**: `https://rpc.sepolia.lisk.com`
- **Chain ID**: 4202
- **Block Explorer**: https://sepolia-blockscout.lisk.com
- **Faucet**: https://sepolia-faucet.lisk.com

### Adding Lisk Sepolia to MetaMask
1. Open MetaMask
2. Click on the network dropdown
3. Select "Add Network"
4. Enter the following details:
   - **Network Name**: Lisk Sepolia
   - **New RPC URL**: https://rpc.sepolia.lisk.com
   - **Chain ID**: 4202
   - **Currency Symbol**: ETH
   - **Block Explorer URL**: https://sepolia-blockscout.lisk.com

## 🚀 Deployment History

| Version | Contract Address | Network | Date | Notes |
|---------|------------------|---------|------|-------|
| v1.0.0 | `0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C` | Lisk Sepolia | 2024-12-19 | Initial deployment |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`npm test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions or support:
- Open an issue in this repository
- Contact the development team
- Check the documentation

## 🔗 Links

- **Contract on Explorer**: [View Contract](https://sepolia-blockscout.lisk.com/address/0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C)
- **Lisk Documentation**: [Lisk Docs](https://docs.lisk.com)
- **OpenZeppelin Contracts**: [OpenZeppelin](https://docs.openzeppelin.com/contracts/)
- **Hardhat Documentation**: [Hardhat](https://hardhat.org/docs)

---

**🌱 GreenLedger - Bringing transparency and trust to agriculture through blockchain technology**
