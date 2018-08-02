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
var _membership = "0x6c1da2347a08c296ff2cb322365dbe3ef0873fd4";// mainnet

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
//var _membership = "0x50d9bf95bf09d6ea9812da2763eac32d21ca31d5"; //rinkeby


//var type = "ETH/USD";
var factory_address= "0xa6fc8ed0d94a33de24eda0c226546ffa3737358a";//7day rinkeby
//var factory_address= "0x29327a6718b00596abceb2da720f83725af8a7ba";//1 day rinkeby
//var factory_address = "0x8207cea5aa1a9047b6607611c2b5b3f04df7b0d3"; //7day mainnet

var type = "BTC/USD";
//var factory_address = "0x804870d9b8184e12444405e1ee114757b97897b8"; //7day rinkeby
//var factory_address = "0x9ff0c23d9aba6cdde2c75b1b8c85c23e7d305aac"; //1day rinkeby
//var factory_address = "0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c"; //7day mainnet


var _memberAddress = "0x5639637f5530b91ad88b5b7264ce928144f8afde";
var _membershipType =1;
var _whitelistTypes = [1];
var _memberId = 3;


console.log( type, factory_address);
module.exports =async function(callback) {
     //let membership = await Membership.new();
       let membership = await Membership.at(_membership);
      console.log("membership address: ", membership.address);
      sleep_s(5);
      let factory = await Factory.at(factory_address);
      console.log("set factory");
      sleep_s(10);
      await factory.setMemberContract(membership.address);
      console.log('factory.setMemberContract');
      sleep_s(10);
      await factory.setWhitelistedMemberTypes(_whitelistTypes);
      console.log('whitelist types ', _whitelistTypes);
      sleep_s(10);
      await factory.isWhitelisted(_memberAddress);
      console.log('whitelist member ', _memberAddress);
      sleep_s(10);
      await membership.setMembershipType(_memberAddress,  _membershipType);
      console.log('membership type added for ', _memberAddress, _membershipType);
      sleep_s(10);
      await membership.setMemberId(_memberAddress,  _memberId);
      console.log('memberId added for ', _memberAddress, _memberId);
      sleep_s(10);
      var getinfo = await membership.getMember(_memberAddress);
      console.log("member infor:", getinfo );
}
