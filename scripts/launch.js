var Oracle = artifacts.require("Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Wrapped_Ether2 = artifacts.require("Wrapped_Ether2");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Tokendeployer = artifacts.require("Tokendeployer");


module.exports =async function(callback) {
  let factory = await Factory.deployed();
  let base1 = await  Wrapped_Ether.deployed();
  let base2 = await Wrapped_Ether2.deployed();
  let deployer = await Deployer.deployed();
  let userContract = await UserContract.deployed();
  let tokenDeployer = await Tokendeployer.deployed();
  let oracle = await Oracle.deployed();
  await factory.setVariables(1000000000000000,1000000000000000,1,1);
  console.log(factory.address);
  await factory.setBaseTokens(base1.address,base2.address);
  await factory.setUserContract(userContract.address);
  await factory.setDeployer(deployer.address);
  await factory.settokenDeployer(tokenDeployer.address);
  await factory.setOracleAddress(oracle.address);
  await userContract.setFactory(factory.address);
  await oracle.PushData();
  console.log(await factory.oracle_address.call() , oracle.address);

}
