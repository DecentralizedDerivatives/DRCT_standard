var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var o_startdate =1532649600;
/*var factory_address= "0x15bd4d9dd2dfc5e01801be8ed17392d8404f9642";*/
var factory_address= "0xbb966cce6e880b17d35d2575f5124d880e0c247f";

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
