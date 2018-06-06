
var Exchange = artifacts.require("./Exchange.sol");


module.exports = async function(deployer, callback) {
  await deployer.deploy(Exchange);
};
