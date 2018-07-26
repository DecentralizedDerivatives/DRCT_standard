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

//var o_startdate =1532304000; //epoch time
//var hdate ="7/23/2018"; //human readable date

var o_startdate =1532649600; //epoch time
var hdate ="7/27/2018"; //human readable date



//var factory_address= "0x804870d9b8184e12444405e1ee114757b97897b8";//BTC
//var factory_address = "0x9ff0c23d9aba6cdde2c75b1b8c85c23e7d305aac"; //1day BTC
//var factory_address = "0xa6fc8ed0d94a33de24eda0c226546ffa3737358a";//ETH
var factory_address= "0x29327a6718b00596abceb2da720f83725af8a7ba";//1 day

console.log(hdate, o_startdate);

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
    
    long_token_add =await factory.long_tokens(o_startdate);
    console.log("long token add", long_token_add);
    short_token_add =await factory.short_tokens(o_startdate);
    console.log("short token add",short_token_add );
    long_token =await DRCT_Token.at(long_token_add);
    console.log("long token ", long_token.address);
    short_token = await DRCT_Token.at(short_token_add);
    console.log("short token ", short_token.address);

    var receipt = await factory.deployContract(o_startdate);
	swap_add = receipt.logs[0].args._created;
	swap = await TokenToTokenSwap.at(swap_add);
	console.log('My Swap',swap_add);
	await userContract.Initiate(swap_add,500000000000000000,{value: web3.toWei(1,'ether')});
    await short_token.transfer('0x323cef35598e3d2d1819c5168a1c68f609ac1e0f',500);
    console.log("afterTranfer");
}
