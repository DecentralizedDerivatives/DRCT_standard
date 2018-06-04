var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "governments of the industrial world you weary giants of flesh and steel";
//this is for ropsten only (hence it's public)
//don't store real Ether here
//don't steal all my Ropsten eth
//Address - 0xc69c64c226fea62234afe4f5832a051ebc860540
//Private Key - fcbd6aa2cfb71561036a4c39d38df5e521c48f314c3a5047b97c538e491eab85

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gasPrice: 1, // Specified in Wei
      gas:15000000
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io"),
      network_id: 3,
      gas: 4612388,
      gasPrice: 50000000000 // Specified in Wei
    }
  }
};

