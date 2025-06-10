const { ethers } = require("hardhat");

async function main() {
  console.log("🌱 Deploying CropBatchToken contract...\n");

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

    // Deploy the contract
  const CropBatchToken = await ethers.getContractFactory("CropBatchToken");
  const cropBatchToken = await CropBatchToken.deploy(
    defaultAdmin,
    baseUri,
    royaltyRecipient,
    royaltyBps
  );

  await cropBatchToken.deployed();

  console.log("\n✅ CropBatchToken deployed to:", cropBatchToken.address);
  console.log("Transaction hash:", cropBatchToken.deployTransaction.hash);

  // Verify deployment
  console.log("\n🔍 Verifying deployment...");

  const owner = await cropBatchToken.owner();
  const hasAdminRole = await cropBatchToken.hasRole(await cropBatchToken.DEFAULT_ADMIN_ROLE(), defaultAdmin);
  const hasFarmerRole = await cropBatchToken.hasRole(await cropBatchToken.FARMER_ROLE(), defaultAdmin);
  const nextTokenId = await cropBatchToken.nextTokenId();
  const royaltyInfo = await cropBatchToken.royaltyInfo(1, 10000);

  console.log("- Owner:", owner);
  console.log("- Admin has DEFAULT_ADMIN_ROLE:", hasAdminRole);
  console.log("- Admin has FARMER_ROLE:", hasFarmerRole);
  console.log("- Next Token ID:", nextTokenId.toString());
  console.log("- Royalty Info:", {
    recipient: royaltyInfo[0],
    amount: royaltyInfo[1].toString()
    });

  console.log("\n🚀 Next Steps:");
  console.log("1. Grant FARMER_ROLE to farmer addresses:");
  console.log(`   await contract.grantFarmerRole("0xFarmerAddress")`);
  console.log("\n2. Mint your first crop batch token:");
  console.log(`   await contract.mint("ipfs://QmYourMetadataHash", "0x")`);

  return cropBatchToken.address;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then((address) => {
    console.log(`\n🎉 Deployment completed successfully!`);
    console.log(`Contract address: ${address}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
      process.exit(1);
    });
