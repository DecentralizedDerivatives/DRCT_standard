const Web3 = require('web3');
require('dotenv').config();
var HDWalletProvider = require("truffle-hdwallet-provider");

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;

var web3 = new Web3(web3.currentProvider);
var web3 = new Web3(new HDWalletProvider(mnemonic,"https://rinkeby.infura.io/"+ accessToken));
var accountFrom= '0xc69c64c226fea62234afe4f5832a051ebc860540';
/*var accountFrom = web3.eth.getAccounts().call((function(error, result){
    if (!error)
        console.log(result);
}));
console.log(accountFrom);*/
var gas_Price= 4000000000;
var gas_Limit= 4700000;

var Factory = artifacts.require("Factory");
var factoryAbi = Factory.abi;
var factoryByte = Factory.bytecode;


var swapFee = 0; //.05% = 500
//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby
var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// rinkeby btc
//var _factoryEth = "0xf55e6ce774cec3817467aed5f5a5769f006658d0";// rinkeby eth

//var _factoryDud = "0xa58d1ea78cd1b610d5dc08c57b1f9fea185061cd"; //MAINNET
//var _factoryBtc = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43";// Mainnet btc
//var _factoryEth = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a";// Mainnet eth
//gas: gas_Limit, gasPrice: gas_Price



module.exports =async function(callback) {
var factory = await new web3.eth.Contract(factoryAbi,_factoryBtc);
console.log(factory.methods);
console.log(factory.options.address);
console.log(_factoryBtc);
await factory.methods.getVariables().call().then(console.log);
var subscription = await web3.eth.subscribe('pendingTransactions', function(error, result){
    if (!error)
        console.log(result);
})
.on("data", function(transaction){
    console.log(transaction);
});

await factory.methods.setSwapFee(0).send({from: accountFrom,gas: gas_Limit,gasPrice: gas_Price })
.on('transactionHash', function(hash){
    var txhash = hash;
    console.log(hash);
})
.on('error', console.error); // If there's an out of gas error the second parameter is the receipt.
;

// unsubscribes the subscription
await subscription.unsubscribe(function(error, success){
    if(success)
        console.log('Successfully unsubscribed!');
});

}

async function fetchTopFive(sub) {
  const URL = `https://www.reddit.com/r/${sub}/top/.json?limit=5`;
  try {
    const fetchResult = fetch(URL)
    const response = await fetchResult;
    const jsonData = await response.json();
    console.log(jsonData);
  } catch(e){
    throw Error(e);
  }
}

fetchTopFive('javvascript'); // Notice the incorrect spelling