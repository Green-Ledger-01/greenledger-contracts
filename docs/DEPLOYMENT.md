# GreenLedger Deployment Details

## 🚀 Live Contracts (Lisk Sepolia)

| Contract | Address | Explorer |
|----------|---------|----------|
| UserManagement | `0xACb3006347dAEa28a511733840999d040aABf9aA` | [View](https://sepolia-blockscout.lisk.com/address/0xACb3006347dAEa28a511733840999d040aABf9aA) |
| CropBatchToken | `0x801055F1dD9C0CFC91B2834eEE2b28662803beB5` | [View](https://sepolia-blockscout.lisk.com/address/0x801055F1dD9C0CFC91B2834eEE2b28662803beB5) |

**Deployed**: December 19, 2024 | **Deployer**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`

## ⚙️ Configuration

**Royalty**: 2.5% to `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`
**Max Batch Size**: 100 kg
**Admin**: `0xF65781317f8E35891CD2edDa1Db26e56ba53B736`

## 🚀 Deploy

```bash
npx hardhat run scripts/deploy-full.js --network lisk
```

**Status**: ✅ Both contracts deployed and verified successfully

## 🧪 Test Contracts

```bash
npx hardhat console --network lisk
```

```javascript
// Connect to contracts
const userManagement = await ethers.getContractAt('UserManagement', '0xACb3006347dAEa28a511733840999d040aABf9aA');
const cropBatchToken = await ethers.getContractAt('CropBatchToken', '0x801055F1dD9C0CFC91B2834eEE2b28662803beB5');

// Register farmer and mint token
await userManagement.registerUser('0xFarmerAddress', 0);
await cropBatchToken.mintNewBatch('0xFarmerAddress', 'Wheat', 50, 'Farm', Date.now(), 'Notes', 'ipfs://QmHash');
```

---

**Deployment completed successfully** ✅
