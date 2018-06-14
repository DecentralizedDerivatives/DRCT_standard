// use ganache-cli -m waxfang
/*
Owner account
AD - 0x711e2b65be4a0201bb8c8e26646366d066d42daa
PK - e495a0d39ae99327ea09eace1f6096a5a3cddeec3b52a3ff80b719831be3d695
*/
var Oracle = artifacts.require("Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");

var _oracle_api = "https://api.gdax.com/products/ETH-USD/ticker).price";
var  duration = 7;
var multiplier = 5;
var _master = "0x300ac58f86804ea589102b93d27d9d7a2bb78255";
var _member = "0xde545ff27a2e83e4dc7827bc926bd03a9a7e75e9";

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    let factory;
    let base;
    let deployer;
    let userContract;
    let oracle;
      let res = await masterDeployer.deployFactory();
      res = res.logs[0].args._factory;
      factory = await Factory.at(res);
      console.log('This is your factory address  :  ',factory.address)
      await factory.setVariables(1000000000000000,7,1);
      await factory.setMemberContract(_member);
      await factory.setWhitelistedMemberTypes([0]);
      base = await Wrapped_Ether.deployed();
      userContract = await UserContract.new();
      deployer = await Deployer.new(factory.address);
      oracle = Oracle.new(_oracle_ap);
      await factory.setBaseToken(base.address);
      await factory.setUserContract(userContract.address);
      await factory.setDeployer(deployer.address);
      await factory.setOracleAddress(oracle_address);
      await userContract.setFactory(factory.address);
      console.log('Your new Factory : ',factory.address);
}