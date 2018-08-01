
var Factory = artifacts.require("./Factory.sol");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");



module.exports =async function(deployer) {
factory = await Factory.new();
console.log(factory.address);
};