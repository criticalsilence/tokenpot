require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // .env dosyasındaki değişkenleri yüklemek için

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20", // Kullanacağımız Solidity versiyonu
  networks: {
    // zkSync Sepolia Test Ağı Tanımı
    zkSyncSepoliaTestnet: {
      url: process.env.ZKSYNC_SEPOLIA_RPC_URL || "", // .env dosyasından okunacak
      ethNetwork: "sepolia", // Ethereum L1 ağı (zkSync için gerekli)
      chainId: 300, // zkSync Sepolia Testnet Chain ID
      zksync: true, // Bu ağın bir zkSync ağı olduğunu belirtir
    },
    // İsterseniz Hardhat'in yerel test ağını da burada tutabilirsiniz:
    // hardhat: {
    //   zksync: false, // Bu Hardhat'in standart yerel ağı, zkSync değil
    // },
  },
  // defaultNetwork: "hardhat" // Eğer varsayılan ağı yerel yapmak isterseniz
};