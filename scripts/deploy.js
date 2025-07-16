const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying NFT Marketplace to Core Testnet 2...");

  // Get the ContractFactory and Signers here
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the NFT Marketplace contract
  const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
  
  console.log("Deploying NFT Marketplace...");
  const nftMarketplace = await NFTMarketplace.deploy();
  
  await nftMarketplace.deployed();

  console.log("NFT Marketplace deployed to:", nftMarketplace.address);
  console.log("Transaction hash:", nftMarketplace.deployTransaction.hash);

  // Get the listing price
  const listingPrice = await nftMarketplace.getListingPrice();
  console.log("Listing price:", ethers.utils.formatEther(listingPrice), "ETH");

  // Verify deployment
  console.log("Verifying deployment...");
  const contractCode = await ethers.provider.getCode(nftMarketplace.address);
  if (contractCode === "0x") {
    console.log("❌ Contract deployment failed!");
  } else {
    console.log("✅ Contract deployed successfully!");
  }

  // Save deployment info
  const deploymentInfo = {
    network: "Core Testnet 2",
    contractAddress: nftMarketplace.address,
    deployer: deployer.address,
    transactionHash: nftMarketplace.deployTransaction.hash,
    listingPrice: ethers.utils.formatEther(listingPrice),
    deployedAt: new Date().toISOString()
  };

  console.log("\n=== Deployment Summary ===");
  console.log(JSON.stringify(deploymentInfo, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
