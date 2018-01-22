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
  console.log('set variables',factory.address);
  await factory.setBaseTokens(base1.address,base2.address);
  console.log('set base tokens');
  await factory.setUserContract(userContract.address);
  console.log('set UserContract');
  await factory.setDeployer(deployer.address);
  console.log('set Deployer');
  await factory.settokenDeployer(tokenDeployer.address);
  console.log('set tokenDeployer');
  await factory.setOracleAddress(oracle.address);
  console.log('set Oracle address');
  await userContract.setFactory(factory.address);
  console.log('set Factory')
  await oracle.PushData();
  console.log('Pushed oracle data');
  console.log(await factory.oracle_address.call() , oracle.address, 'both addresses should be the same');

}
