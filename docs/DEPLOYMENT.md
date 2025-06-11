# GreenLedger Contract Deployment Details

## 🚀 Current Deployment

### Contract Information
- **Contract Name**: CropBatchToken
- **Contract Address**: `0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C`
- **Network**: Lisk Sepolia Testnet
- **Chain ID**: 4202
- **Deployment Date**: December 19, 2024
- **Solidity Version**: 0.8.20

### Transaction Details
- **Transaction Hash**: `0x1b37553ff2727ed4c639acbd220c94976193c55f0d578bcecbb8f50354705d8c`
- **Block Explorer**: [View on Lisk Sepolia Explorer](https://sepolia-blockscout.lisk.com/address/0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C)
- **Gas Used**: ~3,000,000 (estimated)
- **Deployer Address**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`

### Constructor Parameters
```javascript
{
  defaultAdmin: "0xF65781317f8E35891CD2edDa1Db26e56ba53B736",
  baseUri: "https://api.greenledger.com/metadata/{id}",
  royaltyRecipient: "0xF65781317f8E35891CD2edDa1Db26e56ba53B736",
  royaltyBps: 250 // 2.5%
}
```

### Contract Configuration
- **Base URI**: `https://api.greenledger.com/metadata/{id}`
- **Royalty Rate**: 2.5% (250 basis points)
- **Royalty Recipient**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`
- **Max Batch Size**: 100 tokens per transaction
- **Owner**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`

### Initial Roles
- **DEFAULT_ADMIN_ROLE**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`
- **FARMER_ROLE**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736` (for testing)

## 🔧 Deployment Process

### Environment Setup
1. **Node.js Version**: v22.16.0
2. **Hardhat Version**: 2.2.1
3. **OpenZeppelin Contracts**: 5.3.0
4. **Network**: Lisk Sepolia Testnet

### Deployment Command
```bash
npx hardhat run scripts/deploy.js --network lisk
```

### Verification Steps
✅ Contract deployed successfully  
✅ Owner correctly set  
✅ Admin role granted to deployer  
✅ Farmer role granted to deployer (for testing)  
✅ Next token ID initialized to 1  
✅ Royalty info configured correctly  

## 📊 Contract Statistics

### Initial State
- **Total Supply**: 0 tokens
- **Next Token ID**: 1
- **Metadata Frozen Count**: 0
- **Active Farmers**: 1 (deployer for testing)

### Contract Size
- **Bytecode Size**: ~24KB (estimated)
- **ABI Functions**: 30+ functions
- **Events**: 10+ events

## 🔗 Quick Access Links

### Block Explorer
- **Contract**: https://sepolia-blockscout.lisk.com/address/0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C
- **Transaction**: https://sepolia-blockscout.lisk.com/tx/0x1b37553ff2727ed4c639acbd220c94976193c55f0d578bcecbb8f50354705d8c
- **Deployer**: https://sepolia-blockscout.lisk.com/address/0xF65781317f8E35891CD2edDa1Db26e56ba53B736

### Network Information
- **RPC URL**: https://rpc.sepolia.lisk.com
- **Chain ID**: 4202
- **Faucet**: https://sepolia-faucet.lisk.com

## 🧪 Testing Commands

### Connect to Contract
```javascript
// Using Hardhat Console
npx hardhat console --network lisk

// Get contract instance
const contract = await ethers.getContractAt('CropBatchToken', '0xB9f4A0edf2805255aE81e7E25bb20b210f8f2a4C');

// Check basic info
await contract.owner();
await contract.nextTokenId();
await contract.totalSupply();
```

### Basic Operations
```javascript
// Grant farmer role
await contract.grantFarmerRole('0xFarmerAddress');

// Mint a token
await contract.mint('ipfs://QmSampleHash', '0x');

// Check token info
await contract.uri(1);
await contract.exists(1);
```

## 📝 Notes

### Deployment Issues Resolved
1. **Node.js Compatibility**: Initially had issues with Node.js 12, resolved by upgrading to v22.16.0
2. **Hardhat Version**: Used compatible versions of Hardhat and OpenZeppelin contracts
3. **Network Configuration**: Successfully configured Lisk Sepolia testnet

### Security Considerations
- Private key is stored in `.env` file (not committed to git)
- Contract uses OpenZeppelin's audited implementations
- Role-based access control is properly implemented
- Reentrancy protection is in place

### Future Improvements
- Consider implementing contract verification on block explorer
- Add more comprehensive metadata validation
- Implement batch operations for role management
- Consider adding pause functionality for emergency situations

## 📞 Support

For deployment-related questions:
1. Check the main README.md for general information
2. Review the contract source code in `contracts/CropBatchToken.sol`
3. Run tests with `npm test` to verify functionality
4. Open an issue if you encounter problems

---

**Deployment completed successfully on December 19, 2024** ✅
