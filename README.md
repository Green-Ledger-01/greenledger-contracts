# GreenLedger Smart Contracts

Blockchain-based platform for tokenizing and tracking crop batches as NFTs on Lisk, providing transparency and traceability in agricultural supply chains.

## 🚀 Live Deployment

| Contract | Address | Explorer |
|----------|---------|----------|
| UserManagement | `0xACb3006347dAEa28a511733840999d040aABf9aA` | [View](https://sepolia-blockscout.lisk.com/address/0xACb3006347dAEa28a511733840999d040aABf9aA) |
| CropBatchToken | `0x801055F1dD9C0CFC91B2834eEE2b28662803beB5` | [View](https://sepolia-blockscout.lisk.com/address/0x801055F1dD9C0CFC91B2834eEE2b28662803beB5) |

**Network**: Lisk Sepolia Testnet (Chain ID: 4202)

## 📄 Architecture

**UserManagement**: Role-based access control for Farmers, Transporters, and Buyers
**CropBatchToken**: ERC1155 NFTs representing crop batches with rich metadata and royalty support

Key features: IPFS metadata, role integration, metadata freezing, reentrancy protection

## 🚀 Getting Started

### Clone the Project
```bash
git clone https://github.com/Green-Ledger-01/greenledger-contracts.git
cd greenledger-contracts
```

### Setup
```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Add your PRIVATE_KEY to .env file
```

### Development
```bash
# Compile contracts
npm run compile

# Deploy to Lisk Sepolia
npx hardhat run scripts/deploy-full.js --network lisk

# Run tests (note: tests skip due to Hardhat compatibility, but contracts work on testnet)
npm test
```

## 🔧 Usage

### Connect to Deployed Contracts
```javascript
// Using Hardhat Console
npx hardhat console --network lisk

// Get contract instances
const userManagement = await ethers.getContractAt('UserManagement', '0xACb3006347dAEa28a511733840999d040aABf9aA');
const cropBatchToken = await ethers.getContractAt('CropBatchToken', '0x801055F1dD9C0CFC91B2834eEE2b28662803beB5');
```

### Register Users & Mint Tokens
```javascript
// Register a farmer
await userManagement.registerUser('0xFarmerAddress', 0); // 0 = Farmer

// Check user roles
const roleStatus = await userManagement.getUserRolesStatus('0xFarmerAddress');
console.log('Is Farmer:', roleStatus.isFarmer);

// Mint crop batch token
await cropBatchToken.mintNewBatch(
  '0xFarmerAddress',
  'Organic Wheat',
  75, // kg
  'Green Valley Farm',
  Math.floor(Date.now() / 1000),
  'Premium organic wheat',
  'ipfs://QmMetadataHash'
);

// Check token details
await cropBatchToken.batchDetails(1);
await cropBatchToken.uri(1);
```

### Key Functions
- **UserManagement**: `registerUser()`, `revokeRole()`, `getUserRolesStatus()`
- **CropBatchToken**: `mintNewBatch()`, `updateTokenUri()`, `freezeMetadata()`

See [API Reference](docs/API_REFERENCE.md) for complete documentation.

## 🌐 Network Info

**Lisk Sepolia Testnet**
- RPC: `https://rpc.sepolia.lisk.com`
- Chain ID: `4202`
- Explorer: https://sepolia-blockscout.lisk.com
- Faucet: https://sepolia-faucet.lisk.com

## 📚 Documentation

- [API Reference](docs/API_REFERENCE.md) - Complete function documentation
- [Deployment Guide](docs/DEPLOYMENT.md) - Deployment details and verification
- [Test Report](docs/TEST_REPORT.md) - Comprehensive test coverage report

---

**🌱 GreenLedger** - Transparent agricultural supply chain tracking on blockchain
