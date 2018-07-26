/**
Use this to create new tokens
*/
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');

var factory_address= "0xa89e5d248b37e895d12f4c6853b65b6ee1966870";

var add1 = "0x323cef35598e3d2d1819c5168a1c68f609ac1e0f"
var add2 = "0xc69c64c226fEA62234aFE4F5832A051EBc860540"

module.exports =async function(callback) {
     let factory = await Factory.at(factory_address)
      var _tokenadd = await factory.token.call();
      console.log('Token address',_tokenadd);
      let _token = await Wrapped_Ether.at(_tokenadd);
      console.log('Brenda Balance', await _token.balanceOf(add1));
      console.log('Nick Balance', await _token.balanceOf(add2));

}

