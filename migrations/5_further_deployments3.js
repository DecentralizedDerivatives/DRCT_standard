var UserContract = artifacts.require("./UserContract.sol");


module.exports = async function(deployer, callback) {
  await deployer.deploy(UserContract);
};
