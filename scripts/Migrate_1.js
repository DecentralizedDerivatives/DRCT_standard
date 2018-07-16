/************Under construction--Not usable yet*****************************/
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
	//tried the awaits with and without the vars below -it did not work
	let drctlib;
	let factory;
	drctlib = await DRCTLibrary.new();
	//tried removing deployer. and it did not work, also tried DRCTLibrary insteas of drctlib
	deployer.link(drctlib,Factory);
	factory = await Factory.new();
	
};


//https://ethereum.stackexchange.com/questions/32550/truffle-how-to-link-deployed-library-by-address-during-migration

/*var web3 = require("web3");
var fs = require("fs");
var solc = require("solc");

web3 = new web3(new web3.providers.HttpProvider("http://localhost:8545"));

var compiledCode = 

solc.compile(fs.readFileSync('./libraries/DRCTLibrary.sol', 'utf8'),1);

var source = compiledCode.contracts[":DRCTLibrary"];

var factorycontract = new  web3.eth.Contract(JSON.parse(source.interface));

factorycontract.deploy({data: source.bytecode}).send({from: Owneraddress, 
gas:1500000}).on('confirmation', function(confirmationNumber, receipt){ 
console.log(confirmationNumber); factorycontract.options.address = 
receipt.contractAddress; }).on('receipt', function(receipt)
{console.log(receipt)})*/