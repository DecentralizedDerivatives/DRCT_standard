var UserContract = artifacts.require("./UserContract.sol");
var Exchange = artifacts.require("./Exchange.sol");
var MemberCoin = artifacts.require("./MemberCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(UserContract);
  deployer.deploy(Exchange);
  deployer.deploy(MemberCoin);
};
