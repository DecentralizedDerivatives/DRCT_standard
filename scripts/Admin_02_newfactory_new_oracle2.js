/**
Deploy new factory and new oracle
---if an oracle exists use the newfactory_with_existing_oracle.js script
*/
 function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
var Oracle = artifacts.require("Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var MasterDeployer = artifacts.require("MasterDeployer");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");

/**
*@dev Current Oracle API's that can be used for BTC/USD or ETH/USD:
* "json(https://api.gdax.com/products/BTC-USD/ticker).price"
* "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
* "json(https://api.gdax.com/products/ETH-USD/ticker).price"
* "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
*/

/**
*@dev Update oracle APIs(two are needed, the second one is used as backup),
*and factory details(duration, multiplier, swapFee)
*the type is only used to print to the console.
*/
var _oracle_api = "json(https://api.gdax.com/products/BTC-USD/ticker).price";
var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price";
var type = "BTC/USD";
var  duration = 7;
var multiplier = 1;
var swapFee = 0;

/**
*@dev Update the addresses below. get these addresses from the log after running 
*1_Admin_setup.js
*/

/*
Factory :  0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c
factory.setVariables
factory.setMemberContract
factory.setWhitelistedMemberTypes
BaseToken:  0xf2740c75f221788cf78c716b953a7f1c769d49b9
UserContract:  0x087cf4934385bbc138c01e5da3cdc37b89a1a4fb
Deployer:  0x062a9ade99f9959499720d8eaa25cfc189d3f4c8
Oracle:  0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34
*/

var _master = "0x58f745e66fc8bb2307e8d73d7dafeda47030113c";
var _member = "0x4286b9997df2af09e186c332e655e9cef71a40fa";
var _wrapped = "0xf2740c75f221788cf78c716b953a7f1c769d49b9";
var _factoryDud = "0xc7755ccdc4aea8948ceb1ed43edb92a73a323382";
var _factoryAdd = "0x58ae23fd188a23a4f1224c3072fc7db40fca8d9c";
var _userContAdd = "0x087cf4934385bbc138c01e5da3cdc37b89a1a4fb";
var _deployerAdd = "0x062a9ade99f9959499720d8eaa25cfc189d3f4c8";
var _oracleAdd = "0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34";

module.exports =async function(callback) {
    console.log("Type,duration, multiplier, swapFee")
    var  ar = [type,duration,multiplier, swapFee];
    console.log(ar.join(', '));
    //let masterDeployer = await MasterDeployer.at(_master);
    sleep_s(10);
    //await masterDeployer.setFactory(_factoryDud);
    sleep_s(10);
    let factory;
    let base;
    let deployer;
    let userContract;
    let oracle;
      //let res = await masterDeployer.deployFactory();
      //sleep_s(10);
      //res = res.logs[0].args._factory;
      //factory = await Factory.at(res);
      //          sleep_s(10);
      //await factory.setVariables(1000000000000000, duration, multiplier, swapFee);
      //        sleep_s(10);
      //await factory.setMemberContract(_member);
      //        sleep_s(10);
      //await factory.setWhitelistedMemberTypes([0]);
      //        sleep_s(10);
      base = await Wrapped_Ether.at(_wrapped);
      //        sleep_s(10);
      //userContract = await UserContract.new();
      //        sleep_s(10);
      //deployer = await Deployer.new(factory.address);
      //        sleep_s(10);
      //oracle = await Oracle.new(_oracle_api,_oracle_api2);
      factory = await Factory.at(_factoryAdd);
      console.log('Factory : ', _factoryAdd);
      sleep_s(10);
      await factory.setBaseToken(base.address);
      console.log('BaseToken: ',base.address);
      sleep_s(10);
      await factory.setUserContract(_userContAdd);
      console.log('UserContract: ',_userContAdd);
      sleep_s(10);
      await factory.setDeployer(_deployerAdd);
      console.log('Deployer: ',_deployerAdd);
      sleep_s(10);
      await factory.setOracleAddress(_oracleAdd);
      console.log('Oracle: ',_oracleAdd);
      sleep_s(30);
      userContract = await UserContract.at(_userContAdd);
      await userContract.setFactory(factory.address);
      sleep_s(10);
      console.log('Factory : ',factory.address);

    console.log("MasterDeployer, Type,duration, multiplier, swapFee, Factory, Oracle, Deployer, UserContract, BaseToken")
    var  ar = [_master,type,duration,multiplier, swapFee, _factoryAdd, _oracleAdd, _deployerAdd, _userContAdd, _wrapped];
    console.log(ar.join(', '));

}