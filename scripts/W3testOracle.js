const Web3 = require('web3');
const fetch = require('node-fetch-polyfill');
require('dotenv').config();
var HDWalletProvider = require("truffle-hdwallet-provider");

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

//https://ethgasstation.info/json/ethgasAPI.json
//https://www.etherchain.org/api/gasPriceOracle
async function fetchGasPrice() {
  const URL = `https://www.etherchain.org/api/gasPriceOracle`;
  try {
    const fetchResult = fetch(URL);
    const response = await fetchResult;
    const jsonData = await response.json();
    console.log(jsonData);
    return(jsonData);
  } catch(e){
    throw Error(e);
  }
}

var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;
//const web3 = getWeb3;
//var  web3 = new Web3("https://rinkeby.infura.io/"+ accessToken);

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

var myContract = artifacts.require("Test_Oracle2");
var myContractAbi = myContract.abi;
var myContractByte = myContract.bytecode;


var swapFee = 0; //.05% = 500
//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby
var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// rinkeby btc
//var _factoryEth = "0xf55e6ce774cec3817467aed5f5a5769f006658d0";// rinkeby eth

//var _factoryDud = "0xa58d1ea78cd1b610d5dc08c57b1f9fea185061cd"; //MAINNET
//var _factoryBtc = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43";// Mainnet btc
//var _factoryEth = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a";// Mainnet eth
//gas: gas_Limit, gasPrice: gas_Price

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);
var o_startdate = 1531958400;
//ETH oracle
var _oracleEth = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//rinkeby
//var _oracleEth = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//mainnet
console.log("ETH Oracle: ", _oracleEth);

module.exports =async function(callback) {
  oracle = await myContract.new("json(https://api.gdax.com/products/BTC-USD/ticker).price", "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price");
  
let fetch_gasP = await fetchGasPrice();
let gasP= (fetch_gasP.standard + 2)*1000000000;
console.log(gasP);
/*let accountFrom = await web3.eth.getAccounts();
console.log(accountFrom);*/
    var oracle = await new web3.eth.Contract(myContractAbi,oracle.address);//change oracle.address to _oracleEth
    console.log("awaitOracle")
    sleep_s(30);
//o_startdate, 4, 3,"0x12"
await oracle.methods.pushData(o_startdate, 4, 3,"0x12").send({from: accountFrom,gas: gas_Limit,gasPrice: gasP })
console.log("pushData")
    .on('transactionHash', function(hash){
        console.log("hash", hash);

        /*var txinfo =  web3.eth.getTransaction(hash, function(error, result){
            if (!error)
                console.log(result);
            });*/
        //txinfo =  txinfo.json();
        //console.log("txinfo", txinfo);
        //console.log("txnonce", toString(txinfo.nonce));
        //console.log("blocknumber", toString(txinfo.blockNumber));
        //if (txinfo.blockNumber == null) { 

/*            var subscription = oracle.events.newOraclizeQuery(function(error, event){
                if (!error)
                    console.log(event);
                })
                .on('error', console.error);
                console.log("subscription", subscription);

            // unsubscribes the subscription
            subscription.unsubscribe(function(error, success){
                if(success)
                    console.log('Successfully unsubscribed!');
            });*/
        //} 
    })
    
    .on('receipt', function(receipt){
        // receipt example
        //if (receipt.status != true)
        console.log("recStatus", receipt.status);
        console.log("receipt", receipt);
        //if receipt is null--subscribe?--change web3 to websocket and back to http for re-sending tx
    })
    /*.on('confirmation', function(confirmationNumber, receipt){
        console.log(confirmationNumber);
    })*/

    .on('error', console.error); // If there's an out of gas error the second parameter is the receipt.
}










