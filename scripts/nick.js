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

//var o_startdate =1532044800;
//var hdate = "7/20/2018"; //human readable date

var o_startdate = 1532044800;
var hdate = "07/20/2018";

var type = "ETH/USD";
var factory_address= "0xa18e394d8de8f0203fa89b9f35212a2ecbede48a";


//var type = "BTC/USD";
//var factory_address = "0x5dbc9e739bcc518c4ce3084e597117eb0dc929e6";

console.log(hdate, type, factory_address);
module.exports =async function(callback) {
     let factory = await Factory.new()

      let base;
      let deployer;
      //await factory.deployTokenContract(o_startdate);
      await factory.deployTokenContract(o_startdate);
      var long_token_add =await factory.long_tokens(o_startdate);
      var short_token_add =await factory.short_tokens(o_startdate);
            let short_token = await DRCT_Token.at(short_token_add)
      console.log(short_token_add);
      console.log('actual Factory',factory.address);
      console.log('factory',await short_token.getFactoryAddress())
      console.log('my balance', await short_token.balanceOf("0xc69c64c226fEA62234aFE4F5832A051EBc860540") );
      console.log('token date: ',hdate)
      console.log('Long Token at: ',long_token_add);
      console.log('Short Token at: ',short_token_add);
}
