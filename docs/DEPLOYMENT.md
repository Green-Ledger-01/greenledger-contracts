# GreenLedger Deployment Details

## 🚀 Live Contracts (Lisk Sepolia)

| Contract | Address | Explorer |
|----------|---------|----------|
| UserManagement | `0x58C584ddDaAe2DF9Ac73F33F733B876Ffc23CE53` | [View](https://sepolia-blockscout.lisk.com/address/0x58C584ddDaAe2DF9Ac73F33F733B876Ffc23CE53) |
| CropBatchToken | `0x4097236ED51C12a7b57Af129190E0166248709D0` | [View](https://sepolia-blockscout.lisk.com/address/0x4097236ED51C12a7b57Af129190E0166248709D0) |

**Deployed**: December 19, 2024 | **Deployer**: `0xE9aEfF2e55e0B537a89995465cf49EAA4737cfb7`

## ⚙️ Configuration

**Royalty**: 2.5% to `0xE9aEfF2e55e0B537a89995465cf49EAA4737cfb7`
**Max Batch Size**: 100 kg
**Admin**: `0xE9aEfF2e55e0B537a89995465cf49EAA4737cfb7`

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
const userManagement = await ethers.getContractAt('UserManagement', '0x58C584ddDaAe2DF9Ac73F33F733B876Ffc23CE53');
const cropBatchToken = await ethers.getContractAt('CropBatchToken', '0x4097236ED51C12a7b57Af129190E0166248709D0');

// Register farmer and mint token
await userManagement.registerUser('0xFarmerAddress', 0);
await cropBatchToken.mintNewBatch('0xFarmerAddress', 'Wheat', 50, 'Farm', Date.now(), 'Notes', 'ipfs://QmHash');
```

---

**Deployment completed successfully** ✅
