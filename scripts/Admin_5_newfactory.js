/**
Deploy new factory
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
var  duration = 7;
var multiplier = 5;
var swapFee = 0;

/**
*@dev Update the addresses below. get these addresses from the log after running 
*4_Admin_setup.js
*/

var _master = "0x5aa1c552b1c5f70495066c7d9ceeaecab7bebfa8";
var _member = "0xb28b547e8c1c8b551e6c057465bfd802b1567939";
var _wrapped = "0xfe0756975401152e9f14dba904062e6658cccb33";

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