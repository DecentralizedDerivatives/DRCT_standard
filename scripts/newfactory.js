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

var oracle_address = "0x711e2b65be4a0201bb8c8e26646366d066d42daa";
var  duration = 7;
var multiplier = 2;

module.exports =async function(callback) {
      let oracle;
    let factory;
    let base;
    let deployer;
    let userContract;
    let masterDeployer;
      masterDeployer = await MasterDeployer.deployed();
      let res = await masterDeployer.deployFactory();
      res = res.logs[0].args._factory;
      factory = await Factory.at(res);
      console.log('This is your factory address  :  ',factory.address)
      await factory.setVariables(1000000000000000,7,1);
      await factory.setMemberContract(memberCoin.address);
      await factory.setWhitelistedMemberTypes([0]);
      base = await Wrapped_Ether.deployed();
      userContract = await UserContract.new();
      deployer = await Deployer.new(factory.address);
      await factory.setBaseToken(base.address);
      await factory.setUserContract(userContract.address);
      await factory.setDeployer(deployer.address);
      await factory.setOracleAddress(oracle_address);
      await userContract.setFactory(factory.address);

}