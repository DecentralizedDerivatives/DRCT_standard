var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var o_startdate =1531440000;
var hdate = "07/13/2018";

//var type = "ETH/USD";
//var factory_address= "0xd47823a9769bec0bc31d3ef8b076d820865f39d0";
var type = "BTC/USD";
var factory_address= "0xb4dab81e95719ea69f08616c221e42489e84da3a";

console.log(hdate, type);
module.exports =async function(callback) {
      let factory = await Factory.at(factory_address)
      let base;
      let deployer;
      await factory.deployTokenContract(o_startdate);
      var long_token_add =await factory.long_tokens(o_startdate);
      var short_token_add =await factory.short_tokens(o_startdate);
      console.log('Long Token at: ',long_token_add);
      console.log('Short Token at: ',short_token_add);
}
