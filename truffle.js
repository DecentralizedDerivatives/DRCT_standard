var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "other tray hint valid buyer fiscal patch fly damp ocean produce wish";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io"),
      network_id: 3,
      gas: 4612388,
      gasPrice: 50000000000 // Specified in Wei
    }
  }
};