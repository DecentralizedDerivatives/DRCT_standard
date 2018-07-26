//require('dotenv').config()
var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "governments of the industrial world you weary giants of flesh and steel"
//var mnemonic = "dda candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

//var mnemonic = process.env.ETH_MNEMONIC;
//var accessToken = process.env.INFURA_ACCESS_TOKEN;
var accessToken= "";


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gasPrice: 1, // Specified in Wei
      gas:4700000
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+ accessToken),
      network_id: 3,
      gas: 4700000,
      gasPrice: 17e9
    },
     rinkeby: {
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/zkGX3Vf8njIXiHEGRueB"),
      network_id: 4,
      gas: 4700000,
      gasPrice: 17e9
    },
     mainnet: {
      provider: new HDWalletProvider(mnemonic, "https://mainnet.infura.io/"+ accessToken),
      network_id: 5,
      gas: 4700000,
      gasPrice: 2000000000
    }
  }
};

