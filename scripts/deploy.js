const hre = require("hardhat");

async function main() {
  // Chainlink VRF v2.5 parametreleri (Base Sepolia için)
  // Güncel Koordinatör Adresi:
  const vrfCoordinatorV2 = "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE";

  // YENİ OLUŞTURDUĞUNUZ VRF v2.5 ABONELİK ID'NİZİ GİRİN
  const subscriptionId = "63185973121424305688036549045361493066358543409201282945994796347132247463343"; 

  // Base Sepolia için gaz şeridi anahtar hash'i (genellikle değişmez)
  const keyHash = "0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71";
  
  console.log("Deploying CosmicJackpot with the following parameters:");
  console.log(`VRF Coordinator: ${vrfCoordinatorV2}`);
  console.log(`Subscription ID: ${subscriptionId}`);
  console.log(`Key Hash: ${keyHash}`);

  // Kontratı bu parametrelerle dağıt
  const cosmicJackpot = await hre.ethers.deployContract("CosmicJackpot", [
    vrfCoordinatorV2,
    subscriptionId,
    keyHash,
  ]);

  await cosmicJackpot.waitForDeployment();

  console.log(`\nCosmicJackpot (VRF v2.5) deployed to: ${cosmicJackpot.target}`);
}

// Dağıtım işlemini çalıştır ve hataları yakala
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
