var UserContract = artifacts.require("./UserContract.sol");

module.exports = function(deployer) {
  deployer.deploy(UserContract);
};
