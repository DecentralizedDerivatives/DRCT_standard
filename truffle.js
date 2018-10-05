require('dotenv').config()
var HDWalletProvider = require("truffle-hdwallet-provider");
var NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker")

//Nick zkGX3Vf8njIXiHEGRueB
//Brenda PM3RtHbQjHxWydyhDi37
//var mnemonic = "governments of the industrial world you weary giants of flesh and steel"
//var mnemonic = "dda candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;



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
/*     rinkeby: {
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/" + accessToken),
      network_id: 4,
      gas: 4700000,
      gasPrice: 17e9
    },*/
/*     mainnet: {
      provider: new HDWalletProvider(mnemonic, "https://mainnet.infura.io/"+ accessToken),
      network_id: 1,
      gas: 4700000,
      gasPrice: 2000000000
    }*/
/*    mainnet: {
      network_id: "1",
      provider: function () {
        var wallet = new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/' + accessToken)
        var nonceTracker = new NonceTrackerSubprovider()
        wallet.engine._providers.unshift(nonceTracker)
        nonceTracker.setEngine(wallet.engine)
        return wallet
      },
      network_id: 1,
      gas: 4700000,
      gasPrice: 3000000000
    },*/
    rinkeby: {
      network_id: "4",
      provider: function () {
        var wallet = new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/' + accessToken)
        var nonceTracker = new NonceTrackerSubprovider()
        wallet.engine._providers.unshift(nonceTracker)
        nonceTracker.setEngine(wallet.engine)
        return wallet
      },
      network_id: 1,
      gas: 4700000,
      gasPrice: 4000000000
    }


  }
};

