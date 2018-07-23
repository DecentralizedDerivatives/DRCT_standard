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
var factory_address= "0x5dbc9e739bcc518c4ce3084e597117eb0dc929e6";//BTC
//var factory_address = "0xa18e394d8de8f0203fa89b9f35212a2ecbede48a";//ETH
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
	  //await userContract.Initiate(swap_add,10000000000000000,{value: web3.toWei(.02,'ether')});
}
