var Membership = artifacts.require("./Membership.sol");


module.exports = async function(deployer, callback) {
  await deployer.deploy(Membership);
};
