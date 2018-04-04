var Oracle = artifacts.require("./Oracle.sol");
var Test_Oracle = artifacts.require("./Test_Oracle.sol");

module.exports = function(deployer){
  deployer.deploy(Oracle);
  deployer.deploy(Test_Oracle);
}