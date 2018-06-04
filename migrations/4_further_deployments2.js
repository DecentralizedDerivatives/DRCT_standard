var Factory = artifacts.require("./Factory.sol");
var Deployer = artifacts.require("./Deployer.sol");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");
var MasterDeployer = artifacts.require("./MasterDeployer.sol");

module.exports = function(deployer) {
	deployer.deploy(DRCTLibrary);
	deployer.link(DRCTLibrary,Factory);
  deployer.deploy(Factory).then(function(){
  	deployer.deploy(MasterDeployer);
    return deployer.deploy(Deployer, Factory.address)
});
};
