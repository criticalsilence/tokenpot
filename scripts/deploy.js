const hre = require("hardhat");

async function main() {
  // Chainlink VRF v2.5 parametreleri (Base Sepolia için)
  // DÜZELTME: Koordinatör adresi, EIP-55 checksum formatına uygun olarak güncellendi.
  const vrfCoordinatorV2 = "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE";

  // !!! ÇOK ÖNEMLİ !!!
  // YENİ OLUŞTURDUĞUNUZ VRF v2.5 ABONELİK ID'NİZİ TIRNAKLARIN İÇİNE GİRİN
  const subscriptionId = "63185973121424305688036549045361493066358543409201282945994796347132247463343"; 

  // Base Sepolia için gaz şeridi anahtar hash'i (genellikle değişmez)
  const keyHash = "0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71";
  
  // Dağıtım öncesi parametreleri kontrol için konsola yazdır
  console.log("Deploying CosmicJackpot with VRF v2.5 parameters:");
  console.log(`VRF Coordinator: ${vrfCoordinatorV2}`);
  console.log(`Subscription ID: ${subscriptionId}`);
  console.log(`Key Hash: ${keyHash}`);

  // Subscription ID'nin güncellenip güncellenmediğini kontrol et
  if (subscriptionId === "YOUR_NEW_V2_5_SUBSCRIPTION_ID" || subscriptionId === "") {
      console.error("\nLütfen deploy.js dosyasındaki 'subscriptionId' değişkenini kendi abonelik ID'niz ile güncelleyin!");
      process.exit(1);
  }

  // Kontratı bu parametrelerle dağıt
  const cosmicJackpot = await hre.ethers.deployContract("CosmicJackpot", [
    vrfCoordinatorV2,
    subscriptionId,
    keyHash,
  ]);

  await cosmicJackpot.waitForDeployment();

  console.log(`\n✅ CosmicJackpot (VRF v2.5) deployed to: ${cosmicJackpot.target}`);
}

// Dağıtım işlemini çalıştır ve hataları yakala
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
