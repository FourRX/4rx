require('dotenv').config();
const HDWalletProvider = require('truffle-hdwallet-provider-privkey');
const privateKeys = process.env.PRIVATE_KEYS || ""

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 0xfffffffffff,
      gasPrice: 0x01,
      networkId: '*',
    },
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555,         // <-- If you change this, also set the port option in .solcover.js.
      gas: 0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01      // <-- Use this low gas price
    },
    kovan: {
      provider: function(){
        return new HDWalletProvider(
            privateKeys.split(','),
            `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`
        )
      },
      gas: 7000000,
      gasPrice: 25000000000,
      network_id: 42
    }
  }
};
