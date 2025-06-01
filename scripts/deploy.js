const hre = require("hardhat");
const ethers = require("ethers"); 

async function main() {
  console.log(`Running deploy script for the TokenPot contract...`);

  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Private key not found in .env file. Please add DEPLOYER_PRIVATE_KEY.");
  }

  const provider = hre.ethers.provider;
  const wallet = new ethers.Wallet(privateKey, provider);

  const TokenPotFactory = await hre.ethers.getContractFactory("TokenPot", wallet);
  
  console.log("Deploying TokenPot contract...");
  
  const minimumBet = hre.ethers.parseEther("0.001"); 

  const tokenPotContract = await TokenPotFactory.deploy(minimumBet);

  await tokenPotContract.waitForDeployment();

  const contractAddress = await tokenPotContract.getAddress();
  console.log(`TokenPot contract deployed to: ${contractAddress}`);
  console.log(`Minimum bet set to: ${hre.ethers.formatEther(minimumBet)} ETH`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});