/**
Fund Oracles
*/
var Oracle = artifacts.require("Oracle");

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);

//BTC oracle
//var _oracleBtc = "0x488adf792b598db87ff8af711d0f19601f31c3e7";//rinkeby
var _oracleBtc = "0x98cb5fc6ce37b4c4dceab510a56af254c551b705"; //new rinkeby
//var  _oracleBtc= "0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34"; //mainnet


//ETH oracle
//var _oracleEth = "0x6be49e4e660aa759f468669b0a5696e73b537cb7";//rinkeby
var _oracleEth = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//new rinkeby
//var _oracleEth = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//mainnet


module.exports =async function(callback) {
 
    console.log("Funding Oracle ETH");
    let oracle = await Oracle.at(_oracleEth);
    await oracle.fund({value: web3.toWei(.1,'ether')});
    console.log("ETHOracle", _oracleEth);

    console.log("Funding Oracle BTC");
    let oracle2 = await Oracle.at(_oracleBtc);
    await oracle2.fund({value: web3.toWei(.1,'ether')});
    console.log("BTCOracle", _oracleBtc);
}