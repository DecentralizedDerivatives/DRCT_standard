/**
Deploy new factory
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Oracle = artifacts.require("Oracle");
var Wrapped_Ether = artifacts.require("WETH9");
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
//var _oracle_api = "json(https://api.gdax.com/products/ETH-USD/ticker).price";
//var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price";
var type = "BTC/USD";
var  duration = 1;
var multiplier = 100;
var swapFee = 500; //.05%

/**
*@dev Update the addresses below. get these addresses from the log after running 
*4_Admin_setup.js
*/
//BTC oracle
var _oracle = "0x98cb5fc6ce37b4c4dceab510a56af254c551b705"; //rinkeby

//ETH oracle
//var _oracle = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//rinkeby


var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
var _member = "0x50d9bf95bf09d6ea9812da2763eac32d21ca31d5";//rinkeby
var _wrapped = "0x6248cb8a316fc8f1488ce56f6ea517151923531a";//rinkeby

module.exports =async function(callback) {
    console.log("Type,duration, multiplier, swapFee")
    var  ar = [type,duration,multiplier, swapFee];
    console.log(ar.join(', '));
    //let masterDeployer = await MasterDeployer.at(_master);
    //let factory;
    let base;
    //let deployer;
    //let userContract;
    let oracle;
/*      let res = await masterDeployer.deployFactory();
      sleep_s(10);
      res = res.logs[0].args._factory;
      factory = await Factory.at(res);
      console.log('Factory : ',factory.address);
      sleep_s(10);
      await factory.setVariables(1000000000000000, duration, multiplier, swapFee);
      console.log("set variables");
      sleep_s(10);
      await factory.setMemberContract(_member);
      console.log("set membercontract");
      sleep_s(10);
      await factory.setWhitelistedMemberTypes([0]);
      console.log("set whitelisted");
      sleep_s(10);
      base = await Wrapped_Ether.at(_wrapped);
      console.log('BaseToken: ',base.address);
      sleep_s(10);
      userContract = await UserContract.new();
      console.log('UserContract: ',userContract.address);
      sleep_s(10);
      deployer = await Deployer.new(factory.address);
      console.log('Deployer: ',deployer.address);
      sleep_s(10);*/
      let factory = await Factory.at("0x523b08e7afaf851874aa469cc79ad365547f41a7");
      sleep_s(10);
/*      await factory.setBaseToken(base.address);
      console.log("set base token");
      sleep_s(10);*/
      let userContract = await UserContract.at("0xf1ef96cb909005398068657e104fc765e8bbd110");
      let deployer = await Deployer.at("0xfdd2aa8ce6fd51fc0af85c858abb8282a2579af7");
      sleep_s(10);
      await factory.setUserContract(userContract.address);
      //await factory.setUserContract("0xf1ef96cb909005398068657e104fc765e8bbd110");
      console.log("set user contract");
      sleep_s(10);
      await factory.setDeployer(deployer.address);
         //   await factory.setDeployer("");
      console.log("set deployer");
      sleep_s(10);
      await factory.setOracleAddress(_oracle);
      console.log('Oracle: ',_oracle);
      sleep_s(10);
            await userContract.setFactory(factory.address);
      console.log("set factory address for user contract");
      sleep_s(10);
          
/*    console.log("MasterDeployer, Type,duration, multiplier, swapFee, Factory, Oracle, Deployer, UserContract, BaseToken")
    var  ar = [masterDeployer.address,type,duration,multiplier, swapFee, factory.address, _oracle, deployer.address, userContract.address, base.address];
    console.log(ar.join(', '));*/

}