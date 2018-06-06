var MasterDeployer = artifacts.require("./MasterDeployer.sol");


module.exports = async function(deployer, callback) {
  await deployer.deploy(MasterDeployer);
};
