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

//var factory_address= "0xa18e394d8de8f0203fa89b9f35212a2ecbede48a";//ETH
var factory_address= "0x5dbc9e739bcc518c4ce3084e597117eb0dc929e6";//BTC
var _ex = "0x5c9b3e0774dadf6977d6b13d4cf149736318fc32";


console.log(hdate, factory_address);
module.exports =async function(callback) {
      long_token_add = "0x65Fb67cBC2Be794D54E2E8fA9576833d2B038e06"
      let long_token =await DRCT_Token.at(long_token_add);
      console.log(await long_token.getFactoryAddress());
}