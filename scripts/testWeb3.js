/**
*Daily summary.
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

//ETH_MNEMONIC='governments of the industrial world you weary giants of flesh and steel'
INFURA_ACCESS_TOKEN='PM3RtHbQjHxWydyhDi37'

const{getWeb3, getContractInstance, getExistContract} = require('./helpers');
const web3_1_0 = getWeb3;
const getInstance = getContractInstance(web3_1_0);

var MasterDeployer = artifacts.require("MasterDeployer");
var Wr = Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var TokenToTokenSwap = artifacts.require("TokenToTokenSwap");
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var _date = Date.now()/1000- (Date.now()/1000)%86400;



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

var swapFee = 0; //.05% = 500

//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby
//var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// Mainnet btc
//var _factoryEth = "0xf55e6ce774cec3817467aed5f5a5769f006658d0";// Mainnet eth

var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// rinkeby btc
module.exports =async function(accounts, callback) {
	//var Factory = getInstance('Factory', accounts[0]);
/*	const instance = await Factory.deploy().send();
    console.log(instance.options.address);*/
    let factoryW3 = await getExistContract('Factory', _factoryBtc);
    console.log(factoryW3.options.address); 
/*    let factory;
    //let factoryW3 = await new web3.eth.Contract(abi_factory, _factoryBtc);
    console.log(factoryW3.options.address); 
    sleep_s(10);
    factory = await Factory.at(_factoryBtc);
    sleep_s(10);
    let res = await factory.setSwapFee(swapFee);
    sleep_s(30);
    res1 = await res.tx;
    console.log(res1);
    res2 = await res.receipt;
    console.log(res2);
    await web3.eth.filter("pending").watch(
      function(error,result){
          if (!error) {
          	  out = web3.eth.getTransactionReceipt(res1)
              console.log("pending" + result);
              console.log(out.status);
              
          }
      }
    ) */

}



/*#!/usr/bin/env node
const Web3 = require('web3');

const web3 = new Web3(new Web3.providers.WebsocketProvider('wss://mainnet.infura.io/ws'));

const subscription = web3.eth.subscribe('newBlockHeaders', (error, blockHeader) => {
if (error) return console.error(error);

console.log('Successfully subscribed!', blockHeader);
}).on('data', (blockHeader) => {
console.log('data: ', blockHeader);
});

// unsubscribes the subscription
subscription.unsubscribe((error, success) => {
if (error) return console.error(error);

console.log('Successfully unsubscribed!');
});*/