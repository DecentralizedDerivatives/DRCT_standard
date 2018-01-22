var Wrapped_Ether = artifacts.require("./Wrapped_Ether.sol");

module.exports = function(deployer){
  deployer.deploy(Wrapped_Ether);
}