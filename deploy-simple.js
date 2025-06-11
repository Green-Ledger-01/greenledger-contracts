const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

// Simple deployment script that works without Hardhat network issues
async function deployContract() {
    console.log("🌱 Deploying CropBatchToken contract...\n");

    // Create a local provider (you can change this to connect to a real network)
    const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
    
    // Create a wallet (you should use a proper private key for real deployment)
    const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Default Hardhat account
    const wallet = new ethers.Wallet(privateKey, provider);
    
    console.log("Deploying with account:", wallet.address);
    
    try {
        const balance = await wallet.getBalance();
        console.log("Account balance:", ethers.utils.formatEther(balance), "ETH");
    } catch (error) {
        console.log("⚠️  Could not connect to local network. Please start a local blockchain first:");
        console.log("   npx hardhat node");
        console.log("\nOr deploy to a testnet by updating the provider URL and private key.");
        return;
    }

    // Read the compiled contract artifacts
    const artifactsPath = path.join(__dirname, "artifacts", "contracts", "CropBatchToken.sol", "CropBatchToken.json");
    
    if (!fs.existsSync(artifactsPath)) {
        console.error("❌ Contract artifacts not found. Please compile first:");
        console.error("   npx hardhat compile");
        return;
    }

    const contractArtifacts = JSON.parse(fs.readFileSync(artifactsPath, "utf8"));
    const { abi, bytecode } = contractArtifacts;

    // Contract deployment parameters
    const defaultAdmin = wallet.address;
    const baseUri = "https://api.greenledger.com/metadata/{id}";
    const royaltyRecipient = wallet.address;
    const royaltyBps = 250; // 2.5%

    console.log("\n📋 Deployment Parameters:");
    console.log("- Default Admin:", defaultAdmin);
    console.log("- Base URI:", baseUri);
    console.log("- Royalty Recipient:", royaltyRecipient);
    console.log("- Royalty BPS:", royaltyBps, "(2.5%)");

    // Create contract factory
    const contractFactory = new ethers.ContractFactory(abi, bytecode, wallet);

    try {
        console.log("\n🚀 Deploying contract...");
        
        // Deploy the contract
        const contract = await contractFactory.deploy(
            defaultAdmin,
            baseUri,
            royaltyRecipient,
            royaltyBps,
            {
                gasLimit: 3000000 // Set a reasonable gas limit
            }
        );

        console.log("⏳ Waiting for deployment confirmation...");
        await contract.deployed();

        console.log("\n✅ CropBatchToken deployed successfully!");
        console.log("📍 Contract address:", contract.address);
        console.log("🔗 Transaction hash:", contract.deployTransaction.hash);

        // Verify deployment by calling some view functions
        console.log("\n🔍 Verifying deployment...");
        
        try {
            const owner = await contract.owner();
            const hasAdminRole = await contract.hasRole(await contract.DEFAULT_ADMIN_ROLE(), defaultAdmin);
            const hasFarmerRole = await contract.hasRole(await contract.FARMER_ROLE(), defaultAdmin);
            const nextTokenId = await contract.nextTokenId();

            console.log("- Owner:", owner);
            console.log("- Admin has DEFAULT_ADMIN_ROLE:", hasAdminRole);
            console.log("- Admin has FARMER_ROLE:", hasFarmerRole);
            console.log("- Next Token ID:", nextTokenId.toString());

            // Test royalty info
            const royaltyInfo = await contract.royaltyInfo(1, 10000);
            console.log("- Royalty Info:", {
                recipient: royaltyInfo[0],
                amount: royaltyInfo[1].toString()
            });

        } catch (verifyError) {
            console.log("⚠️  Could not verify all contract functions:", verifyError.message);
        }

        // Save deployment info
        const deploymentInfo = {
            contractAddress: contract.address,
            transactionHash: contract.deployTransaction.hash,
            deployerAddress: wallet.address,
            network: "local", // Change this based on your network
            deployedAt: new Date().toISOString(),
            constructorArgs: {
                defaultAdmin,
                baseUri,
                royaltyRecipient,
                royaltyBps
            }
        };

        const deploymentPath = path.join(__dirname, "deployment.json");
        fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
        console.log("\n📄 Deployment info saved to:", deploymentPath);

        console.log("\n🚀 Next Steps:");
        console.log("1. Grant FARMER_ROLE to farmer addresses:");
        console.log(`   await contract.grantFarmerRole("0xFarmerAddress")`);
        console.log("\n2. Mint your first crop batch token:");
        console.log(`   await contract.mint("ipfs://QmYourMetadataHash", "0x")`);
        console.log("\n3. Update metadata URI if needed:");
        console.log(`   await contract.updateTokenUri(tokenId, "ipfs://QmNewMetadataHash")`);
        console.log("\n4. Freeze metadata when ready:");
        console.log(`   await contract.freezeMetadata(tokenId)`);

        console.log("\n📝 Contract Interaction Example:");
        console.log("```javascript");
        console.log("const { ethers } = require('ethers');");
        console.log(`const contractAddress = "${contract.address}";`);
        console.log("const abi = [...]; // Use the ABI from artifacts");
        console.log("const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545');");
        console.log("const contract = new ethers.Contract(contractAddress, abi, provider);");
        console.log("```");

        return contract.address;

    } catch (deployError) {
        console.error("\n❌ Deployment failed:");
        console.error(deployError.message);
        
        if (deployError.message.includes("insufficient funds")) {
            console.log("\n💡 Tip: Make sure your account has enough ETH for deployment");
        } else if (deployError.message.includes("network")) {
            console.log("\n💡 Tip: Make sure you're connected to the correct network");
            console.log("   For local development: npx hardhat node");
        }
    }
}

// Run the deployment
if (require.main === module) {
    deployContract()
        .then((address) => {
            if (address) {
                console.log(`\n🎉 Deployment completed successfully!`);
                console.log(`📍 Contract address: ${address}`);
            }
            process.exit(0);
        })
        .catch((error) => {
            console.error("\n❌ Deployment script failed:");
            console.error(error);
            process.exit(1);
        });
}

module.exports = { deployContract };
