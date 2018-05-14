var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var days_future = 0;

module.exports =async function(callback) {
      let factory = await Factory.deployed();
      let base;
      let deployer;
      var o_startdate = Date.now()/1000+86400*days_future - (Date.now()/1000)%86400;
      var o_enddate = o_startdate + 86400*7+86400*days_future;
      await factory.deployTokenContract(o_startdate);
      var long_token_add =await factory.long_tokens(o_startdate);
      var short_token_add =await factory.short_tokens(o_startdate);
      console.log('Long Token at: ',long_token_add);
      console.log('Short Token at: ',short_token_add);
      console.log('End Date: ',o_enddate);
      await factory.deployTokenContract(o_enddate);
}
