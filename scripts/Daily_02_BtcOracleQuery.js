/**
*Send Oraclize query for the orales being used in each factory under
*the master deployer specified.
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Oracle = artifacts.require("Oracle");

/**
*@dev Update Eth oracle address if it has changed.
*_nowUTC is only used to display a human readable date on the console.
*/

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);

//BTC oracle
//var _oracleBtc = "0x98cb5fc6ce37b4c4dceab510a56af254c551b705"; //rinkeby
var  _oracleBtc= "0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34"; //mainnet
console.log("BTC Oracle: ", _oracleBtc);

module.exports =async function(callback) {
    let oracle = await Oracle.at(_oracleBtc);
    console.log("awaitOracle")
    sleep_s(30);
    await oracle.pushData();
    console.log("pushData")
    sleep_s(30);
    console.log("BTC oracle query sent successfully");
}
