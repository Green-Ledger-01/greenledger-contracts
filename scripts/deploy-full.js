const { ethers } = require("hardhat");

async function main() {
  console.log("🌱 Deploying GreenLedger Smart Contracts...\n");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Contract deployment parameters
  const defaultAdmin = deployer.address; // Admin will be the deployer
  const baseUri = "https://api.greenledger.com/metadata/{id}"; // Base URI for metadata
  const royaltyRecipient = deployer.address; // Royalty recipient (can be changed later)
  const royaltyBps = 250; // 2.5% royalty

  console.log("\n📋 Deployment Parameters:");
  console.log("- Default Admin:", defaultAdmin);
  console.log("- Base URI:", baseUri);
  console.log("- Royalty Recipient:", royaltyRecipient);
  console.log("- Royalty BPS:", royaltyBps, "(2.5%)");

  // Step 1: Deploy UserManagement contract
  console.log("\n🔐 Deploying UserManagement contract...");
  const UserManagement = await ethers.getContractFactory("UserManagement");
  const userManagement = await UserManagement.deploy(defaultAdmin);
  await userManagement.deployed();

  console.log("✅ UserManagement deployed to:", userManagement.address);
  console.log("Transaction hash:", userManagement.deployTransaction.hash);

  // Step 2: Deploy CropBatchToken contract
  console.log("\n🌾 Deploying CropBatchToken contract...");
  const CropBatchToken = await ethers.getContractFactory("CropBatchToken");
  const cropBatchToken = await CropBatchToken.deploy(
    userManagement.address,
    baseUri,
    royaltyRecipient,
    royaltyBps
  );
  await cropBatchToken.deployed();

  console.log("✅ CropBatchToken deployed to:", cropBatchToken.address);
  console.log("Transaction hash:", cropBatchToken.deployTransaction.hash);

  // Step 3: Verify deployments
  console.log("\n🔍 Verifying deployments...");

  // Verify UserManagement
  const hasAdminRole = await userManagement.hasRole(await userManagement.DEFAULT_ADMIN_ROLE(), defaultAdmin);
  const farmerRole = await userManagement.FARMER_ROLE();
  const transporterRole = await userManagement.TRANSPORTER_ROLE();
  const buyerRole = await userManagement.BUYER_ROLE();

  console.log("\n📋 UserManagement Verification:");
  console.log("- Admin has DEFAULT_ADMIN_ROLE:", hasAdminRole);
  console.log("- FARMER_ROLE:", farmerRole);
  console.log("- TRANSPORTER_ROLE:", transporterRole);
  console.log("- BUYER_ROLE:", buyerRole);
  console.log("- Contract is paused:", await userManagement.paused());

  // Verify CropBatchToken
  const userMgmtAddress = await cropBatchToken.userManagementContract();
  const nextTokenId = await cropBatchToken.nextTokenId();
  const maxBatchSize = await cropBatchToken.MAX_BATCH_SIZE();
  const adminRoleForCrops = await cropBatchToken.ADMIN_ROLE_FOR_CROPS();

  console.log("\n🌾 CropBatchToken Verification:");
  console.log("- UserManagement Address:", userMgmtAddress);
  console.log("- Next Token ID:", nextTokenId.toString());
  console.log("- Max Batch Size:", maxBatchSize.toString());
  console.log("- Admin Role for Crops:", adminRoleForCrops);

  // Test royalty info (need to create a token first)
  console.log("\n💰 Testing Royalty System...");
  try {
    // Grant farmer role to deployer for testing
    await userManagement.registerUser(deployer.address, 0); // 0 = Farmer
    console.log("- Granted farmer role to deployer");

    // Mint a test token
    await cropBatchToken.mintNewBatch(
      deployer.address,
      "Test Wheat",
      50,
      "Test Farm",
      Math.floor(Date.now() / 1000),
      "Test deployment batch",
      "ipfs://QmTestHash123456789"
    );
    console.log("- Minted test token with ID 1");

    // Check royalty info
    const royaltyInfo = await cropBatchToken.royaltyInfo(1, 10000);
    console.log("- Royalty Info:", {
      recipient: royaltyInfo[0],
      amount: royaltyInfo[1].toString()
    });
  } catch (error) {
    console.log("- Royalty test failed (expected in some cases):", error.message);
  }

  // Step 4: Setup initial roles (optional)
  console.log("\n👥 Setting up initial roles...");
  try {
    // Grant admin role for crops to deployer
    await userManagement.grantRole(adminRoleForCrops, deployer.address);
    console.log("- Granted ADMIN_ROLE_FOR_CROPS to deployer");
  } catch (error) {
    console.log("- Role setup note:", error.message);
  }

  console.log("\n🚀 Next Steps:");
  console.log("1. Register users with roles:");
  console.log(`   await userManagement.registerUser("0xFarmerAddress", 0) // Farmer`);
  console.log(`   await userManagement.registerUser("0xTransporterAddress", 1) // Transporter`);
  console.log(`   await userManagement.registerUser("0xBuyerAddress", 2) // Buyer`);
  console.log("\n2. Mint your first crop batch token:");
  console.log(`   await cropBatchToken.mintNewBatch(`);
  console.log(`     "0xRecipientAddress",`);
  console.log(`     "Wheat",`);
  console.log(`     50,`);
  console.log(`     "Green Valley Farm",`);
  console.log(`     ${Math.floor(Date.now() / 1000)},`);
  console.log(`     "Organic wheat batch",`);
  console.log(`     "ipfs://QmYourMetadataHash"`);
  console.log(`   )`);

  console.log("\n📊 Deployment Summary:");
  console.log("- UserManagement:", userManagement.address);
  console.log("- CropBatchToken:", cropBatchToken.address);
  console.log("- Network:", (await ethers.provider.getNetwork()).name);
  console.log("- Chain ID:", (await ethers.provider.getNetwork()).chainId);

  return {
    userManagement: userManagement.address,
    cropBatchToken: cropBatchToken.address
  };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then((addresses) => {
    console.log(`\n🎉 Deployment completed successfully!`);
    console.log(`UserManagement: ${addresses.userManagement}`);
    console.log(`CropBatchToken: ${addresses.cropBatchToken}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
