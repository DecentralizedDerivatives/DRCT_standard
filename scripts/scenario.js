var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Exchange = artifacts.require("Exchange");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Migrations = artifacts.require("../contracts/Migrations.sol");


//var o_startdate = 1532649600;
//var hdate = "07/27/2018";

var o_startdate = 1532044800;
var hdate = "07/20/2018";
var factory_address= "0x8822b11262fb2f6c201e6fed8a3098b32851cc42";
//var factory_address= "0xf45902281e917bcbeb70ebb574b6949e5ac8c8b2";
var _ex = "0x8536b232de448f8e3896de4ac3c85a38b50e7953";

//old-----var factory_address= "0x15bd4d9dd2dfc5e01801be8ed17392d8404f9642";
console.log(hdate, factory_address);
module.exports =async function(callback) {
      let swap;
      let factory = await Factory.at(factory_address);
      let u_address = await factory.user_contract.call();
      let userContract = await UserContract.at(u_address);
      let exchange = await Exchange.at(_ex);
      var swap_add;
      var long_token_add =await factory.long_tokens(o_startdate);
      var short_token_add =await factory.short_tokens(o_startdate);
      let long_token =await DRCT_Token.at(long_token_add);
      let short_token = await DRCT_Token.at(short_token_add);
      var receipt = await factory.deployContract(o_startdate);
	  swap_add = receipt.logs[0].args._created;
	  swap = await TokenToTokenSwap.at(swap_add);
	  console.log('My Swap',swap_add);
	  await userContract.Initiate(swap_add,100000000000000000,{value: web3.toWei(.2,'ether')});
      await long_token.approve(exchange.address,50);
      await short_token.approve(exchange.address,50);
      await exchange.list(long_token_add,50,web3.toWei(.05,'ether'));
      await exchange.list(short_token_add,50,web3.toWei(.05,'ether'));
}