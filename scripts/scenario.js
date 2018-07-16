var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Exchange = artifacts.require("Exchange");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Migrations = artifacts.require("../contracts/Migrations.sol");

var o_startdate =1531440000;
var hdate = "07/13/2018"; //human readable date

//var o_startdate = 1532044800;
//var hdate = "07/20/2018";

//var o_startdate = 1532649600;
//var hdate = "07/27/2018";

//var factory_address= "0xdfb380afc0948e9551fd17b486681122b5936c2a";//ETH
var factory_address= "0x95c9c47558115b12f25dce5103e73e0803a5b9c7";//BTC
var _ex = "0x2242ef4a4a1b4510c09c1a4de12cd96b0108d0cb";


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