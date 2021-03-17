require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
require("dotenv").config();
require("hardhat-gas-reporter");

const privateKeys = process.env.PRIVATE_KEYS || ""

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    }
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 119,
    coinmarketcap: process.env.CMC_KEY
  },
  networks: {
    hardhat: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000
    },
    ropsten: {
      'url': `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: privateKeys.split(','),
      gas: 7000000,
      gasPrice: 25000000000,
      network_id: 3,
      networkCheckTimeout: 20000,
      skipDryRun: true,
      chainId: 3
    }
  }
};
