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

var currentTime = new Date() ;
var _date = currentTime.setDate(currentTime.getDate()+14);
var d = (_date - (_date % 86400000))/1000;
console.log("d", d);
var test = new Date(d*1000);
var d2 = test.toUTCString();
console.log("d2", d2);

var o_startdate = d;
var hdate = _date;

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');


/*var o_startdate =1534723200;
var hdate = "8/20/2018";*/


var type = "BTC/USD";
//var factory_address = "0x804870d9b8184e12444405e1ee114757b97897b8"; //7day 1xrinkeby
//var factory_address = "0x9ff0c23d9aba6cdde2c75b1b8c85c23e7d305aac"; //1day 1x rinkeby
//var factory_address = "0x523b08e7afaf851874aa469cc79ad365547f41a7"; //1day 100x rinkeby
var factory_address = "0x92217550aba5912ba7eb70978871daf7d6bcc16d"; //Whitelist change 1x rinkeby

//var factory_address = "0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c"; //7day 1x mainnet
//var factory_address = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43"; //Whitelist change 1x mainnet

console.log("timeRan, startDateEpoch, startDate, type, factory, typeFactory, typeContract, Long, Short")
var ar = [_nowUTC,o_startdate, d2, type, factory_address1];
console.log(ar.join(', '));
module.exports =async function(callback) {
      let factory = await Factory.at(factory_address);
      console.log(", Btc 1x set factory,");
      sleep_s(10);
      //console.log(await factory.getDateCount());
      //console.log(await factory.startDates);
      await factory.deployTokenContract(o_startdate);
      console.log("Btc 1x deployTokenContract,");
      sleep_s(10);
      var long_token_add =await factory.long_tokens(o_startdate);
      console.log('Btc 1x Long Token at: ',long_token_add, ",");
      sleep_s(10);
      var short_token_add =await factory.short_tokens(o_startdate);
      console.log('Btc 1x Short Token at: ',short_token_add);
      sleep_s(10);


}

