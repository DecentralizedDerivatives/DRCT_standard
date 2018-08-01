/**
Use this to create new tokens
*/
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Oracle = artifacts.require("Oracle");

var factory_address= "0x29327a6718b00596abceb2da720f83725af8a7ba";
var s_date = 1532649600;
var e_date = 1532736000;

var add1 = "0x323cef35598e3d2d1819c5168a1c68f609ac1e0f"
var add2 = "0xc69c64c226fEA62234aFE4F5832A051EBc860540"

module.exports =async function(callback) {
     let factory = await Factory.at(factory_address)
      var _tokenadd = await factory.token.call();
      console.log('Token address',_tokenadd);
      let _token = await Wrapped_Ether.at(_tokenadd);
      console.log('Brenda Balance', await _token.balanceOf(add1));
      console.log('Nick Balance', await _token.balanceOf(add2));
      let oracle_address = await factory.oracle_address.call();
      let oracle = await Oracle.at(oracle_address);
 	  var value =  await oracle.retrieveData(s_date);
      var value1= value/1000;
      var value2 =  await oracle.retrieveData(e_date);
      var value2a= value2/1000;
      console.log(value1, value2a);

}

