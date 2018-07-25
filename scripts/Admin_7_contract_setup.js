/**
Use this to create new tokens
*/
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

//BTC/USD, 7, 1, 0, 0x5dbc9e739bcc518c4ce3084e597117eb0dc929e6
//ETH/USD, 7, 5, 0, 0xa18e394d8de8f0203fa89b9f35212a2ecbede48a

//var o_startdate = 1533254400;
//var hdate = "8/3/2018"; //human readable date

//var o_startdate = 1532649600;
//var hdate = "07/27/2018";

//var o_startdate =1532044800; //epoch time
//var hdate ="7/20/2018"; //human readable date

//var o_startdate =1532304000; //epoch time
//var hdate ="7/23/2018"; //human readable date

var o_startdate =1532390400; //epoch time
var hdate ="7/24/2018"; //human readable date

//var type = "ETH/USD";
//var factory_address= "0xa18e394d8de8f0203fa89b9f35212a2ecbede48a";


var type = "BTC/USD";
//var factory_address = "0x5dbc9e739bcc518c4ce3084e597117eb0dc929e6"; //7day
var factory_address = "0xa89e5d248b37e895d12f4c6853b65b6ee1966870"; //1day


console.log(hdate, type, factory_address);
module.exports =async function(callback) {
      let factory = await Factory.at(factory_address)
      let base;
      let deployer;
      await factory.deployTokenContract(o_startdate);
      var long_token_add =await factory.long_tokens(o_startdate);
      var short_token_add =await factory.short_tokens(o_startdate);
      console.log('token date: ',hdate)
      console.log('Long Token at: ',long_token_add);
      console.log('Short Token at: ',short_token_add);
}
