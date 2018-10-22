
/**
*Daily summary.
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var MasterDeployer = artifacts.require("MasterDeployer");
var Wr = Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var TokenToTokenSwap = artifacts.require("TokenToTokenSwap");
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var _date = Date.now()/1000- (Date.now()/1000)%86400;
var web3 = require('web3').web3;
/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer and provide a summary.
*/

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
var _master = "0xe8327b94aba6fbc3a95f7ffaf8dd568e6cd36616"; //rinkeby new dud
var _wrapped= "0x6248cb8a316fc8f1488ce56f6ea517151923531a";//rinkeby new dud
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
//var _master= "0xcd8e11dad961dad43cc3de40df918fe808cbda74"; //maninnet new dud
//var _wrapped= "0xf2740c75f221788cf78c716b953a7f1c769d49b9";//mainnet

module.exports =async function(callback) {
    let wrapped = await Wrapped_Ether.at(_wrapped);
    console.log("wrappped ether");
    let wrappedEth = await wrapped.totalSupply();
    console.log("wrppedEth supply", wrappedEth);

var myAddr = _wrapped;
var currentBlock = await web3.blockNumber;
var n = await web3.getTransactionCount(myAddr, currentBlock);
var bal = await web3.getBalance(myAddr, currentBlock);
for (var i=currentBlock; i >= 0 && (n > 0 || bal > 0); --i) {
    try {
        var block = await web3.getBlock(i, true);
        if (block && block.transactions) {
            await block.transactions.forEach(function(e) {
                if (myAddr == e.from) {
                    if (e.from != e.to)
                        bal = bal.plus(e.value);
                    console.log(i, e.from, e.to, e.value.toString(10));
                    --n;
                }
                if (myAddr == e.to) {
                    if (e.from != e.to)
                        bal = bal.minus(e.value);
                    console.log(i, e.from, e.to, e.value.toString(10));
                }
            });
        }
    } catch (e) { console.error("Error in block " + i, e); }
}
}