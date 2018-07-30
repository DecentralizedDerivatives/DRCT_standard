
var Factory = artifacts.require("./Factory.sol");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");
var solc = require('solc');
var fs = require('fs');
const Web3 = require('web3');

//tried changing deployer to callback-did not work
module.exports =async function(deployer) {
drctlibrary = await DRCTLibrary.deployed();
console.log(drctlibrary.address);
factory = await Factory.new();
console.log(factory.address);
};