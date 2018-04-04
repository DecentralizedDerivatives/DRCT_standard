var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Tokendeployer = artifacts.require("Tokendeployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');


module.exports =async function(callback) {
      let oracle;
      let factory;
      let base;
      let deployer;
      let userContract;
      let tokenDeployer;
      o_startdate = Date.now() - Date.now()%86400;
      o_enddate = o_startdate + 86400*7;
      balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
      balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
      await factory.deployTokenContract(o_startdate,true);
      await factory.deployTokenContract(o_startdate,false);
      long_token_add =await factory.long_tokens(o_startdate);
      short_token_add =await factory.short_tokens(o_startdate);
      long_token =await DRCT_Token.at(long_token_add);
      short_token = await DRCT_Token.at(short_token_add);
      await oracle.StoreDocument(o_startdate,1000);
      await oracle.StoreDocument(o_enddate,1500);
}
