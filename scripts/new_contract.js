
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var days_future = 0;

module.exports =async function(callback) {
      let swap;
      let factory = await Factory.deployed();
      let userContract = await UserContract.deployed();
      var swap_add;
      var o_startdate = Date.now()/1000+86400*days_future - (Date.now()/1000)%86400;
      var o_enddate = o_startdate + 86400*7+86400*days_future;
      var receipt = await factory.deployContract(o_startdate);
	  swap_add = receipt.logs[0].args._created;
	  swap = await TokenToTokenSwap.at(swap_add);
	  console.log('My Swap',swap_add);
	  await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether')});
}
