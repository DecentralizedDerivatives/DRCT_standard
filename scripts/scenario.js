
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Exchange = artifacts.require("Exchange");
var Tokendeployer = artifacts.require("Tokendeployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var days_future = 7;

module.exports =async function(callback) {
      let swap;
      let factory = await Factory.deployed();
      let userContract = await UserContract.deployed();
      let exchange = await Exchange.deployed();
      var swap_add;
      var o_startdate = Date.now()/1000+86400*days_future - (Date.now()/1000)%86400;
      var o_enddate = o_startdate + 86400*7+86400*days_future;
      var long_token_add =await factory.long_tokens(o_startdate);
      var short_token_add =await factory.short_tokens(o_startdate);
      let long_token =await DRCT_Token.at(long_token_add);
      let short_token = await DRCT_Token.at(short_token_add);
      var receipt = await factory.deployContract(o_startdate);
	  swap_add = receipt.logs[0].args._created;
	  swap = await TokenToTokenSwap.at(swap_add);
	  console.log('My Swap',swap_add);
	  await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether')});
      await long_token.approve(exchange.address,500);
      await short_token.approve(exchange.address,500);
      await exchange.list(long_token_add,500,web3.toWei(.5,'ether'));
      await exchange.list(short_token_add,500,web3.toWei(.5,'ether'));
}