/**
*Test deploy new swap
*/
var Factory = artifacts.require("./Factory.sol");
var UserContract= artifacts.require("UserContract");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');

/**
*@dev Update the swap start date, hdate(human readable date is used only in 
* the console) and factory address
*/

var o_startdate =1532044800; //epoch time
var hdate ="7/20/2018"; //human readable date
var factory_address= "0x95c9c47558115b12f25dce5103e73e0803a5b9c7";//BTC
//var factory_address = "0xdfb380afc0948e9551fd17b486681122b5936c2a";//ETH
console.log(hdate);

module.exports =async function(callback) {
    let swap;
    let factory = await Factory.at(factory_address);
    let u_address = await factory.user_contract.call();
    let userContract = await UserContract.at(u_address);
    var swap_add;
    var accounts;
    // in web front-end, use an onload listener and similar to this manual flow ... 
    web3.eth.getAccounts(function(err,res) { 
        if(err){
            console.log('err',err);
      }
    console.log('My Account: ',res);
    accounts = res; 
    });

    var receipt = await factory.deployContract(o_startdate);
	  swap_add = receipt.logs[0].args._created;
	  swap = await TokenToTokenSwap.at(swap_add);
	  console.log('My Swap',swap_add);
	  await userContract.Initiate(swap_add,500000000000000000,{value: web3.toWei(1,'ether')});
}
