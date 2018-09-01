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
var _date = currentTime.setDate(currentTime.getDate()+1);
var d = (_date - (_date % 86400000))/1000;
console.log("_date",_date);
console.log("d", d);

var o_startdate = d;
var hdate = _date;

/*var o_startdate =1534723200;
var hdate = "8/20/2018";*/



var type = "BTC/USD";
//var factory_address = "0x804870d9b8184e12444405e1ee114757b97897b8"; //7day 1xrinkeby
//var factory_address = "0x9ff0c23d9aba6cdde2c75b1b8c85c23e7d305aac"; //1day 1x rinkeby
var factory_address = "0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c"; //7day 1x mainnet
//var factory_address = "0x523b08e7afaf851874aa469cc79ad365547f41a7"; //1day 100x rinkeby

var type1 = "ETH/USD";
//var factory_address= "0xa6fc8ed0d94a33de24eda0c226546ffa3737358a";//7day 5x rinkeby
//var factory_address= "0x29327a6718b00596abceb2da720f83725af8a7ba";//1 day 5x rinkeby
var factory_address1 = "0x8207cea5aa1a9047b6607611c2b5b3f04df7b0d3"; //7day 5x mainnet

console.log(hdate, type, factory_address, o_startdate);
module.exports =async function(callback) {
      let factory = await Factory.at(factory_address);
      console.log("Btc 1x set factory");
      sleep_s(10);
      console.log(await factory.getDateCount());
      //console.log(await factory.startDates);
      await factory.deployTokenContract(o_startdate);
      console.log("Btc 1x deployTokenContract");
      sleep_s(10);
      var long_token_add =await factory.long_tokens(o_startdate);
      console.log('Btc 1x Long Token at: ',long_token_add);
      sleep_s(10);
      var short_token_add =await factory.short_tokens(o_startdate);
      console.log('Btc 1x Short Token at: ',short_token_add);
      sleep_s(10);

      let factoryEth = await Factory.at(factory_address1);
      console.log("Eth 5x set factoryEth");
      sleep_s(10);
      console.log(await factoryEth.getDateCount());
      //console.log(await factory.startDates);
      await factoryEth.deployTokenContract(o_startdate);
      console.log("Eth 5x deployTokenContract");
      sleep_s(10);
      var long_token_add =await factoryEth.long_tokens(o_startdate);
      console.log('Eth 5x Long Token at: ',long_token_add);
      sleep_s(10);
      var short_token_add =await factoryEth.short_tokens(o_startdate);
      console.log('Eth 5x Short Token at: ',short_token_add);
      sleep_s(10);

}

