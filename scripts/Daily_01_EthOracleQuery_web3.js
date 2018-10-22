require('dotenv').config();
const Web3 = require('web3');
const fetch = require('node-fetch-polyfill');
var HDWalletProvider = require("truffle-hdwallet-provider");

/**
*Send Oraclize query for the orales being used in each factory under
*the master deployer specified.
*/

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
    const gasPriceNow = await jsonData.standard*1;
    const gasPriceNow2 = await (gasPriceNow + 1)*1000000000;
    console.log(jsonData);
    //console.log("gasPriceNow", gasPriceNow);
    //console.log("gasPriceNow2", gasPriceNow2);
    return(gasPriceNow2);
  } catch(e){
    throw Error(e);
  }
}

var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;
var oracleAbi = Oracle.abi;
var oracleByte = Oracle.bytecode;
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
var gas_Limit= 4700000;


/**
*@dev Update Eth oracle address if it has changed.
*_nowUTC is only used to display a human readable date on the console.
*/

//ETH oracle
var _oracleEth = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//rinkeby
var accountFrom= '0xc69c64c226fea62234afe4f5832a051ebc860540'; //rinkeby

//var _oracleEth = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//mainnet
//var accountFrom = '0x074993DeE953F2706ae318e11622b3EE0b7850C3';//mainnet

console.log(_nowUTC);
console.log("ETH Oracle: ", _oracleEth);

module.exports =async function(callback) {
	var gasP = await fetchGasPrice();
    console.log("gasP1", gasP);
    var oracle = await new web3.eth.Contract(oracleAbi,_oracleEth);
    console.log("awaitOracle");
    sleep_s(30);
    await oracle.methods.pushData.send({from: accountFrom,gas: gas_Limit,gasPrice: gasP })
        .on('transactionHash', function(hash){
            console.log("hash", hash);
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

    console.log("pushData")
    sleep_s(30);
    console.log("Eth oracle query sent successfully");
}
