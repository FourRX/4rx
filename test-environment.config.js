module.exports = {
    accounts: {
        amount: 10, // Number of unlocked accounts
        ether: 100, // Initial balance of unlocked accounts (in ether)
    },

    contracts: {
        type: 'truffle', // Contract abstraction to use: 'truffle' for @truffle/contract or 'web3' for web3-eth-contract
        defaultGas: 0x1fffffffffffff, // Maximum gas for contract calls (when unspecified)

        // Options available since v0.1.2
        defaultGasPrice: 0x1, // Gas price for contract calls (when unspecified)
        artifactsDir: 'build/contracts', // Directory where contract artifacts are stored
    },

    node: { // Options passed directly to Ganache client
        gasLimit: 0x1fffffffffffff, // Maximum gas per block
        gasPrice: 0x1, // Sets the default gas price for transactions if not otherwise specified.
        allowUnlimitedContractSize: true
    },
};
