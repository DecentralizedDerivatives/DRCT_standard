// use ganache-cli -m waxfang
/*
Owner account
AD - 0x711e2b65be4a0201bb8c8e26646366d066d42daa
PK - e495a0d39ae99327ea09eace1f6096a5a3cddeec3b52a3ff80b719831be3d695
*/
var Oracle = artifacts.require("Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var MasterDeployer = artifacts.require("MasterDeployer");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");

/**
*oracle API's:
*e.g. "json(https://api.gdax.com/products/BTC-USD/ticker).price"
* "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
* or "json(https://api.gdax.com/products/ETH-USD/ticker).price"
* "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
*/
var _oracle_api = "json(https://api.gdax.com/products/BTC-USD/ticker).price";
var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price";
var type = "BTC/USD";
var  duration = 7;
var multiplier = 1;
var swapFee = 0;

/**
*@dev Get these addresses from the log after running 3_Deploy_setup.js
*/
var _master = "0xf9ed40905386323f14317f1fa42ac21ffd29cba5";
var _member = "0xe4c559b57f9af24ed13d40d1c63b3eb94778e8f8";
var _wrapped = "0x22eecfc947de216ddd2aaccbda463e461884dbf9";

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

}