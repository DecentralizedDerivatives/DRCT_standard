const Web3 = require('web3');

function getWeb3() {
	const myWeb3 = new Web3(web3.currentProvider);
	return myWeb3;
}

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

accessToken ='PM3RtHbQjHxWydyhDi37'
//const web3 = getWeb3;
var  web3 = new Web3("https://rinkeby.infura.io/"+ accessToken);
var myContract = artifacts.require("Oracle");
var myContractAbi = myContract.abi;


var swapFee = 0; //.05% = 500
//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby
var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// rinkeby btc
//var _factoryEth = "0xf55e6ce774cec3817467aed5f5a5769f006658d0";// rinkeby eth

//var _factoryDud = "0xa58d1ea78cd1b610d5dc08c57b1f9fea185061cd"; //MAINNET
//var _factoryBtc = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43";// Mainnet btc
//var _factoryEth = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a";// Mainnet eth

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);

//ETH oracle
var _oracleEth = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//rinkeby
//var _oracleEth = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//mainnet
console.log("ETH Oracle: ", _oracleEth);




module.exports =async function(callback) {
    var oracle = await new web3.eth.Contract(myContractAbi,_oracleEth);
    console.log("awaitOracle")
    sleep_s(30);
    await oracle.pushData();
    console.log("pushData")
    sleep_s(30);
    console.log("Eth oracle query sent successfully");


var factory = await new web3.eth.Contract(factoryAbi,_factoryBtc);
console.log(factory.methods);
console.log(factory.options.address);
console.log(_factoryBtc);
await factory.methods.getVariables().call().then(console.log);
}

