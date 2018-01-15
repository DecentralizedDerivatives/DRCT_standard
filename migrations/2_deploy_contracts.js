var Oracle = artifacts.require("./Oracle.sol");
var Wrapped_Ether = artifacts.require("./Wrapped_Ether.sol");
var Wrapped_Ether2 = artifacts.require("./Wrapped_Ether2.sol");
var Factory = artifacts.require("./Factory.sol");
var Deployer = artifacts.require("./Deployer.sol");
var Tokendeployer = artifacts.require("./Tokendeployer.sol");
var UserContract = artifacts.require("./UserContract.sol");
var UserContract = artifacts.require("./UserContract.sol");
var DRCT_Token = artifacts.require("./DRCT_Token.sol");
var DRCT_Token2 = artifacts.require("./DRCT_Token2.sol");


module.exports = function(deployer) {
  deployer.deploy(Oracle);
  deployer.deploy(Wrapped_Ether);
  deployer.deploy(Wrapped_Ether2);
  deployer.deploy(Factory).then(function(){
    return deployer.deploy(Deployer, Factory.address).then(function(){
    	return deployer.deploy(Tokendeployer, Factory.address)
    });
});
  deployer.deploy(UserContract);
};
