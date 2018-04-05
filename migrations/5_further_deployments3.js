var UserContract = artifacts.require("./UserContract.sol");
var Exchange = artifacts.require("./Exchange.sol");

module.exports = function(deployer) {
  deployer.deploy(UserContract);
  deployer.deploy(Exchange);
};
