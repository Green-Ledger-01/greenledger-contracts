async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with:", deployer.address);
  
    const unlockTime = Math.floor(Date.now() / 1000) + 60 * 60 * 24; // 24 hours from now
  
    const Lock = await ethers.getContractFactory("Lock");
  
    // Deploy the contract
    const lock = await Lock.deploy(unlockTime, {
      value: ethers.parseEther("0.00001"),
    });
  
    // Wait for the deployment to be confirmed
    await lock.waitForDeployment();
  
    console.log("Lock deployed to:", await lock.getAddress());
    console.log("Unlock time:", unlockTime);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
