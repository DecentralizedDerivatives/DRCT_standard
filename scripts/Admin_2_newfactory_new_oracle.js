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
var _oracle_api = "json(https://api.gdax.com/products/ETH-USD/ticker).price";
var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price";
var type = "ETH/USD";
var  duration = 7;
var multiplier = 5;
var swapFee = 0;

/**
*@dev Update the addresses below. get these addresses from the log after running 
*1_Admin_setup.js
*/

var _master = "0x58f745e66fc8bb2307e8d73d7dafeda47030113c";
var _member = "0x4286b9997df2af09e186c332e655e9cef71a40fa";
var _wrapped = "0xf2740c75f221788cf78c716b953a7f1c769d49b9";

module.exports =async function(callback) {
    console.log("Type,duration, multiplier, swapFee")
    var  ar = [type,duration,multiplier, swapFee];
    console.log(ar.join(', '));
    let masterDeployer = await MasterDeployer.at(_master);
    let factory;
    let base;
    let deployer;
    let userContract;
    let oracle;
      let res = await masterDeployer.deployFactory();
      sleep_s(5);
      res = res.logs[0].args._factory;
      factory = await Factory.at(res);
                sleep_s(5);
      await factory.setVariables(1000000000000000, duration, multiplier, swapFee);
              sleep_s(5);
      await factory.setMemberContract(_member);
              sleep_s(5);
      await factory.setWhitelistedMemberTypes([0]);
              sleep_s(5);
      base = await Wrapped_Ether.at(_wrapped);
              sleep_s(5);
      userContract = await UserContract.new();
              sleep_s(5);
      deployer = await Deployer.new(factory.address);
              sleep_s(5);
      oracle = await Oracle.new(_oracle_api,_oracle_api2);
              sleep_s(5);
      await factory.setBaseToken(base.address);
              sleep_s(5);
      await factory.setUserContract(userContract.address);
              sleep_s(5);
      await factory.setDeployer(deployer.address);
              sleep_s(5);
      await factory.setOracleAddress(oracle.address);
              sleep_s(5);
      await userContract.setFactory(factory.address);
              sleep_s(5);
      console.log('Factory : ',factory.address);
      console.log('Oracle: ',oracle.address);
      console.log('Deployer: ',deployer.address);
      console.log('UserContract: ',userContract.address);
      console.log('BaseToken: ',base.address);
    console.log("MasterDeployer, Type,duration, multiplier, swapFee, Factory, Oracle, Deployer, UserContract, BaseToken")
    var  ar = [masterDeployer.address,type,duration,multiplier, swapFee, factory.address, oracle.address, deployer.address, userContract.address, base.address];
    console.log(ar.join(', '));

}