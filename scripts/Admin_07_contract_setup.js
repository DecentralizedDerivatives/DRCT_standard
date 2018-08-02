/**
Use this to create new tokens
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');

/**
*@dev Update the factory address and the start date (o_startdate) 
*as epoch date to create tokens
*Update hdate to reflect the epoch date as a human readable date and type
*both hdate and type are only used to output to the console
*/

var o_startdate = 1533859200;
var hdate = "08/10/2018";

//var type = "ETH/USD";
//var factory_address= "0xa6fc8ed0d94a33de24eda0c226546ffa3737358a";//7day rinkeby
//var factory_address= "0x29327a6718b00596abceb2da720f83725af8a7ba";//1 day rinkeby
//var factory_address = "0x8207cea5aa1a9047b6607611c2b5b3f04df7b0d3"; //7day mainnet

var type = "BTC/USD";
//var factory_address = "0x804870d9b8184e12444405e1ee114757b97897b8"; //7day rinkeby
//var factory_address = "0x9ff0c23d9aba6cdde2c75b1b8c85c23e7d305aac"; //1day rinkeby
var factory_address = "0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c"; //7day mainnet


console.log(hdate, type, factory_address, o_startdate);
module.exports =async function(callback) {
      let factory = await Factory.at(factory_address);
      console.log("set factory");
      sleep_s(10);
      let base;
      let deployer;
      await factory.deployTokenContract(o_startdate);
      sleep_s(10);
      var long_token_add =await factory.long_tokens(o_startdate);
      console.log('Long Token at: ',long_token_add);
      sleep_s(10);
      var short_token_add =await factory.short_tokens(o_startdate);
      console.log('Short Token at: ',short_token_add);
      sleep_s(10);

}
