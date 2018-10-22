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

var type = "ETH/USD";
//var factory_address1= "0xa6fc8ed0d94a33de24eda0c226546ffa3737358a";//7day 5x rinkeby
//var factory_address1= "0x29327a6718b00596abceb2da720f83725af8a7ba";//1 day 5x rinkeby
var factory_address1 = "0xf55e6ce774cec3817467aed5f5a5769f006658d0"; //Whitelist change 5x rinkeby

//var factory_address1 = "0x8207cea5aa1a9047b6607611c2b5b3f04df7b0d3"; //7day 5x mainnet
//var factory_address1 = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a"; //Whitelist change 5x mainnet

console.log("timeRan, startDateEpoch, startDate, type, factory, typeFactory, typeContract, Long, Short")
var ar = [_nowUTC,o_startdate, d2, type, factory_address1];
console.log(ar.join(', '));
module.exports =async function(callback) {

      let factoryEth = await Factory.at(factory_address1);
      console.log(", Eth 5x set factoryEth,");
      sleep_s(10);
      //console.log(await factoryEth.getDateCount());
      //console.log(await factory.startDates);
     await factoryEth.deployTokenContract(o_startdate);
      console.log("Eth 5x deployTokenContract,");
      sleep_s(10);
      var long_token_add =await factoryEth.long_tokens(o_startdate);
      console.log('Eth 5x Long Token at: ',long_token_add, ",");
      sleep_s(10);
      var short_token_add =await factoryEth.short_tokens(o_startdate);
      console.log('Eth 5x Short Token at: ',short_token_add);
      sleep_s(10);

}

