/**
Deploy new factory and new oracle
---if an oracle exists use the newfactory_with_existing_oracle.js script
*/
 
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
var  duration = 1;
var multiplier = 5;
var swapFee = 0;

/**
*@dev Update the addresses below. get these addresses from the log after running 
*4_Admin_setup.js
*/

var _master = "0xfce97feb873355d43e9102bbef83a1ed758edddf";
var _member = "0x19550d3ca9775490640e474855d1e1f5cb144dc4";
var _wrapped = "0x09e6a0f3350208bb72e8f399fb467e84517e58c6";

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
      res = res.logs[0].args._factory;
      factory = await Factory.at(res);
      await factory.setVariables(1000000000000000, duration, multiplier, swapFee);
      await factory.setMemberContract(_member);
      await factory.setWhitelistedMemberTypes([0]);
      base = await Wrapped_Ether.at(_wrapped);
      userContract = await UserContract.new();
      deployer = await Deployer.new(factory.address);
      oracle = await Oracle.new(_oracle_api,_oracle_api2);
      await factory.setBaseToken(base.address);
      await factory.setUserContract(userContract.address);
      await factory.setDeployer(deployer.address);
      await factory.setOracleAddress(oracle.address);
      await userContract.setFactory(factory.address);
      console.log('Factory : ',factory.address);
      console.log('Oracle: ',oracle.address);
      console.log('Deployer: ',deployer.address);
      console.log('UserContract: ',userContract.address);
      console.log('BaseToken: ',base.address);
    console.log("MasterDeployer, Type,duration, multiplier, swapFee, Factory, Oracle, Deployer, UserContract, BaseToken")
    var  ar = [masterDeployer.address,type,duration,multiplier, swapFee, factory.address, oracle.address, deployer.address, userContract.address, base.address];
    console.log(ar.join(', '));

}