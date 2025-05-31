const hre = require("hardhat");
const ethers = require("ethers"); // ethers'ı import ediyoruz

async function main() {
  console.log(`Running deploy script for the TokenPot contract...`);

  // .env dosyasından özel anahtarı al
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Private key not found in .env file. Please add DEPLOYER_PRIVATE_KEY.");
  }

  // Hardhat'in mevcut ağ için yapılandırdığı provider'ı (ağ bağlantısını) al
  const provider = hre.ethers.provider;

  // Cüzdanı oluştururken provider'ı (ağ bağlantısını) da ona veriyoruz
  const wallet = new ethers.Wallet(privateKey, provider);

  // Kontratımızın "fabrikasını" alıyoruz. 
  // Hardhat, hardhat.config.js'deki zksync:true bayrağı sayesinde
  // bunun bir zkSync kontratı olduğunu anlar ve doğru fabrikayı verir.
  const TokenPotFactory = await hre.ethers.getContractFactory("TokenPot", wallet);

  console.log("Deploying TokenPot contract...");

  // Minimum bahsi ETH cinsinden belirle (örneğin, 0.001 ETH)
  // Bu değeri kontratınızın constructor'ı bekliyor.
  const minimumBet = hre.ethers.parseEther("0.001");

  // Fabrika üzerinden deploy işlemini gerçekleştir ve constructor argümanını gönder
  const tokenPotContract = await TokenPotFactory.deploy(minimumBet);

  // Deploy işleminin tamamlanmasını bekle
  await tokenPotContract.waitForDeployment();

  const contractAddress = await tokenPotContract.getAddress();
  console.log(`TokenPot contract deployed to: ${contractAddress}`);
  console.log(`Minimum bet set to: ${hre.ethers.formatEther(minimumBet)} ETH`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});