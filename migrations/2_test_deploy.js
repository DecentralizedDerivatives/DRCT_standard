var Factory = artifacts.require("./Factory.sol");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");

module.exports = function(deployer) {
	deployer.deploy(DRCTLibrary);
	deployer.link(DRCTLibrary,Factory);
    deployer.deploy(Factory);
};