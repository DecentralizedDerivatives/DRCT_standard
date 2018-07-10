/**
*@dev Use this for setting up contracts for testing
*this will link the Factory and DRCT Library

*These commands that need to be ran:
*truffle migrate --network rinkeby
*truffle exec scripts/Migrate_1.js --network rinkeby
*truffle exec scripts/Migrate_2.js --network rinkeby
*/
var Factory = artifacts.require("./Factory.sol");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");

//tried changing deployer to callback-did not work
module.exports =async function(deployer) {
	//tried the awaits with and witought the vars below -it did not work
	let drctlib;
	let factory;
	drctlib = await DRCTLibrary.new();
	//tried removing deployer. and it did not work
	deployer.link(drctlib,Factory);
	factory = await Factory.new();
	
};
