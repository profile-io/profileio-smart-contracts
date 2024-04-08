require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const { ALCHEMY_API_KEY, PRIV_KEY, ETH_SCAN_API_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      // url: `https://rpc.ankr.com/eth_sepolia/${ANKR_API_KEY}`,
      accounts: [`${PRIV_KEY}`],
      // blockGasLimit: 30000000
    },
  },
  etherscan: {
    apiKey: {
      sepolia: `${ETH_SCAN_API_KEY}`,
    }
  }
};
