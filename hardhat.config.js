require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    polygonMumbai: {
      url: process.env.POLYGON_MUMBAI_RPC_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    optimismGoerli: {
      url: process.env.OPTIMISM_GOERLI_RPC_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 30000000000,
    },
    baseGoerli: {
      url: process.env.BASE_GOERLI_RPC_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 30000000000,
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      optimisticGoerli: process.env.OPTIMISMSCAN_API_KEY,
      baseGoerli: process.env.BASESCAN_API_KEY,
    },
  },
};
