require('dotenv').config()
var HDWalletProvider = require("truffle-hdwallet-provider");
var NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker")


//Nick zkGX3Vf8njIXiHEGRueB
//Brenda PM3RtHbQjHxWydyhDi37
//var mnemonic = "governments of the industrial world you weary giants of flesh and steel"
//var mnemonic = "dda candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;

/*
***********************Fetch tests*******************************
const Web3 = require('web3');
const fetch = require('node-fetch-polyfill');
var web3 = new Web3(new HDWalletProvider(mnemonic,"https://rinkeby.infura.io/"+ accessToken));

//test vea Async fx
//https://ethgasstation.info/json/ethgasAPI.json
//https://www.etherchain.org/api/gasPriceOracle
async function fetchGasPrice() {
  const URL = `https://www.etherchain.org/api/gasPriceOracle`;
  try {
    const fetchResult = fetch(URL);
    const response = await fetchResult;
    const jsonData = await response.json();
    const gasPriceNow = await jsonData.standard*1;
    const gasPriceNow2 = await (gasPriceNow + 1)*1000000000;
    console.log(jsonData);
    console.log("gasPriceNow", gasPriceNow);
    console.log("gasPriceNow2", gasPriceNow2);
    return(gasPriceNow2);
  } catch(e){
    throw Error(e);
  }
}

var gasP = fetchGasPrice();
console.log("gasP1", gasP);

//test via fx
function fetchOHLC(){
  const URL = `https://www.etherchain.org/api/gasPriceOracle`;
    return fetch(URL)
    .then(response => response.json())
    .then(function(response) {
        var l = response.safeLow;
        var s = response.standard;
        var f = response.fast;
        var ft = response.fastest;
        var gp = response.standard*1;
        var gasPrice = (gp+1)*1000000000;
        console.log("gasprice",gasPrice);
    return gasPrice;
    })
    .catch(function(error) {
        console.log(error);
    });    
}

var fetchData = fetchOHLC();
console.log("fetchData:",fetchData);
var price = fetchData.then(function(result){});
console.log("new Gas Price", price);


//test via web3
var gasPrice2 = web3.eth.gasPrice;
console.log(gasPrice2);
var gasPrice2 = gasPrice.toString(10);
console.log(gasPrice2); // "10000000000000"
*******************************************Fetch test end****************
*/

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
      gasPrice: 4000000000
    },*/

        mainnet: {
      network_id: "1",
      provider: function () {
        var wallet = new HDWalletProvider(mnemonic, 'https://eth-mainnet.alchemyapi.io/jsonrpc/'+ accessToken)
        var nonceTracker = new NonceTrackerSubprovider()
        wallet.engine._providers.unshift(nonceTracker)
        nonceTracker.setEngine(wallet.engine)
        return wallet
      },
      network_id: 1,
      gas: 4700000,
      gasPrice: 4000000000
    },

/*    mainnet: {
      network_id: "1",
      provider: function () {
        var wallet = new HDWalletProvider(mnemonic, 'https://gladly-fond-horse.quiknode.io/8faab5bf-73f6-4f72-a8df-bceb75f0f671/8K5s-t4qrXAHuiIZMLRjNQ==/')
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
      network_id: 4,
      gas: 4700000,
      gasPrice: 4000000000
    }


  }
};

