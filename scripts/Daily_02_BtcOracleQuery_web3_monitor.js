require('dotenv').config();
const Web3 = require('web3');
const fetch = require('node-fetch-polyfill');
var HDWalletProvider = require("truffle-hdwallet-provider");

/**
*Check Btc Oraclize query callback and if failed, re-send.
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
var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;
var oracleAbi = Oracle.abi;
var oracleByte = Oracle.bytecode;
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
var gas_Limit= 4700000;
var web3 = new Web3(new HDWalletProvider(mnemonic,"https://rinkeby.infura.io/"+ accessToken));
var _date = Date.now()/1000- (Date.now()/1000)%86400;

/**
*@dev Update BTC oracle address if it has changed.
*_nowUTC is only used to display a human readable date on the console.
*/

//BTC oracle
var _oracleBtc = "0x98cb5fc6ce37b4c4dceab510a56af254c551b705"; //rinkeby
var accountFrom= '0xc69c64c226fea62234afe4f5832a051ebc860540'; //rinkeby

//var  _oracleBtc= "0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34"; //mainnet
//var accountFrom = '0x074993DeE953F2706ae318e11622b3EE0b7850C3';//mainnet

console.log(_nowUTC);
console.log("ETH Oracle: ", _oracleEth);

module.exports =async function(callback) {
    try{
        var oracle = await new web3.eth.Contract(oracleAbi,_oracleBtc);
        console.log("awaitOracle");
        sleep_s(30);
        var value =  await oracle.methods.retrieveData(_date).call();
        console.log("value",value);
        //console.log("retreive oracle data", value);
        sleep_s(30);
    }  catch(error) {
       console.error(error);
       console.log("BTC oracle value not retreived");
    }
    try{
        var value1= value/1000;
        var link = "".concat('<https://rinkeby.etherscan.io/address/',_oracleBtc,'>' );
        var api = await oracle.methods.getusedAPI().call();
        console.log("api",api);
        sleep_s(30);
        var ar = [ _oracleEth, _nowUTC,  value1, link, api];
        console.log(ar.join(', '));
    } catch(error){
        console.error(error);
        console.log("no API retreived");
    }

    if (value == 0 ) {
    try{
    	var gasP = await fetchGasPrice();
        console.log("gasP1", gasP);
    } catch (error){
        console.error(error);
        console.log("no gas price fetched");
    }
    try{
        await oracle.methods.pushData().send({from: accountFrom,gas: gas_Limit,gasPrice: gasP })
            .on('transactionHash', function(hash){
                var link = "".concat('<https://rinkeby.etherscan.io/tx/',hash,'>' );
                var ownerlink = "".concat('<https://rinkeby.etherscan.io/address/',_oracleBtc,'>' );
                console.log("BTC oracle sent");
                console.log("Hash link: ", link);
                console.log("Contract link: ", ownerlink);
            })
/*            .on('receipt', function(receipt){
                console.log("recStatus", receipt.status);
                console.log("receipt", receipt);
            })*/
            /*.on('confirmation', function(confirmationNumber, receipt){
                console.log(confirmationNumber);
            })*/
            .on('error', console.error); // If there's an out of gas error the second parameter is the receipt.

    } catch(error) {
        console.error(error);

    }
    }
}
