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
  factory.setVariables(1000000000000000,1000000000000000,7,1);
  console.log(factory.address);
  factory.setBaseTokens(base1.address,base2.address);
  factory.setUserContract(userContract.address);
  factory.setDeployer(deployer.address);
  factory.settokenDeployer(tokenDeployer.address);
  await factory.setOracleAddress(oracle.address);
  userContract.setFactory(factory.address);
  console.log(await factory.oracle_address.call() , oracle.address);

}
