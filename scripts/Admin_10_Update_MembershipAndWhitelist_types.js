/**
Use this to create new tokens
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
var Membership = artifacts.require("Membership");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");



/**
*@dev Update the factory address and the start date (o_startdate) 
*as epoch date to create tokens
*Update hdate to reflect the epoch date as a human readable date and type
*both hdate and type are only used to output to the console
*/

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //mainnet
//var _membership = "0xd33615c5ea5d703f06d237f6c56ff2400b564c77";// mainnet

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
var _membership = "0x620b6b6ac75ad9234eb6c533688ddd8a5948650e"; //rinkeby

//var type = "ETH/USD";
//var factory_address= "0xa6fc8ed0d94a33de24eda0c226546ffa3737358a";//7day 5x rinkeby
//var factory_address= "0x29327a6718b00596abceb2da720f83725af8a7ba";//1 day 5x rinkeby
//var factory_address = "0xf55e6ce774cec3817467aed5f5a5769f006658d0"; //Whitelist change 5x rinkeby

//var factory_address = "0x8207cea5aa1a9047b6607611c2b5b3f04df7b0d3"; //7day 5x mainnet
//var factory_address = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a"; //Whitelist change 5x mainnet

var type = "BTC/USD";
//var factory_address = "0x804870d9b8184e12444405e1ee114757b97897b8"; //7day 1x rinkeby
//var factory_address = "0x9ff0c23d9aba6cdde2c75b1b8c85c23e7d305aac"; //1day 1x rinkeby
//var factory_address = "0x523b08e7afaf851874aa469cc79ad365547f41a7"; //1day 100x rinkeby
var factory_address = "0x92217550aba5912ba7eb70978871daf7d6bcc16d"; //Whitelist change 1x rinkeby

//var factory_address = "0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c"; //7day 1x mainnet
//var factory_address = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43"; //Whitelist change 1x mainnet


//var _whitelistTypes = [1,2,3];
var _memberFee = 2500000000000000;
var _swapFee = 500; //.05%


console.log( type, factory_address);
module.exports =async function(callback) {
      let membership = await Membership.at(_membership);
      console.log("membership address: ", membership.address);
      sleep_s(10);
      let factory = await Factory.at(factory_address);
      console.log("set factory");
      sleep_s(10);
      await factory.setMemberContract(membership.address);
      console.log('membership.address:', membership.address);
      sleep_s(10);
/*
      await membership.setFee(_memberFee);
      console.log('set Memberhip fee', _memberFee);
      await factory.setSwapFee(_swapFee);
      console.log('swapFee ', _swapFee);
      sleep_s(10);
      await factory.setWhitelistedMemberTypes(_whitelistTypes);
      console.log('whitelist types ', _whitelistTypes);
      sleep_s(10);*/

}
