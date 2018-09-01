/**
*Send Oraclize query for the orales being used in each factory under
*the master deployer specified.
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");

/**
*@dev Update Eth oracle address if it has changed.
*_nowUTC is only used to display a human readable date on the console.
*/

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);

//ETH oracle
var _oracleEth = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//rinkeby
//var _oracleEth = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//mainnet
console.log("ETH Oracle: ", _oracleEth);

module.exports =async function(callback) {
    let oracle = await Oracle.at(_oracleEth);
    console.log("awaitOracle")
    sleep_s(30);
    await oracle.pushData();
    console.log("pushData")
    sleep_s(30);
    console.log("Eth oracle query sent successfully");
}
