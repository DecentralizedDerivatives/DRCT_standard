var Factory = artifacts.require("./Factory.sol");
var Deployer = artifacts.require("./Deployer.sol");
var Tokendeployer = artifacts.require("./Tokendeployer.sol");

module.exports = function(deployer) {
  deployer.deploy(Factory).then(function(){
    return deployer.deploy(Deployer, Factory.address).then(function(){
    	return deployer.deploy(Tokendeployer, Factory.address)
    });
});
};
