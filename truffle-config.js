// hardhat.config.js
require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider'); 

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", 
      gas: 6721975,
      gasPrice: 20000000000
    },
    lisk: {
      provider: () => new HDWalletProvider(
        process.env.PRIVATE_KEY,
        "https://rpc.api.lisk.com"
      ),
      network_id: 1135,
      gas: 6721975,
      gasPrice: 20000000000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },

  compilers: {
    solc: {
      version: "0.8.20", 
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },

  plugins: ["truffle-plugin-verify"],

  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  }
};