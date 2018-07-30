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
var solc = require('solc');
var fs = require('fs');

//tried changing deployer to callback-did not work
module.exports =async function(deployer) {
	//console.log(Factory);
	var factoryByte = await {'./build/contracts/Factory.json': fs.readFileSync('./build/contracts/Factory.json').toString()};
	console.log(factoryByte);
	let drctlib;
	let factory;
	drctlib = await DRCTLibrary.new();
	console.log("DRCTLibrary", drctlib.address);
    var linkedFactory = await String(factoryByte).replace(/_+DRCTLibrary_+/g, drctlib.address.replace("0x", ""));
    console.log(linkedFactory);    
    fs.writeFile('./build/contracts/compiled.json', JSON.stringify(linkedFactory), function(err) {
        if (err) throw err;
        console.log('Compiled & saved');
    });
};

	//solc --optimize --bin Factory.sol | solc --link --libraries DRCTLibrary:drctlib.address
	//factory = await Factory.new();
/*var solc = require('solc');
var fs = require('fs');

var inputs = {
    'auction.sol': fs.readFileSync('auction.sol').toString(),
};

// Assumes imported files are in the same folder/local path
function findImports(path) {
    return {
        'contents': fs.readFileSync(path).toString()
    }
}

var compiledCode = solc.compile({sources: inputs}, 1, findImports)

fs.writeFile('compiled.json', JSON.stringify(compiledCode), function(err) {
    if (err) throw err;
    console.log('Compiled & saved');
});
*/



/*var fs = require('fs')
var path = require('path')

function findImports(importPath, sourcePath) {
  try {
    var filePath = path.resolve(sourcePath, importPath)
    return { contents: fs.readFileSync(filePath).toString() }
  } catch (e) {
    return { error: e.message }
  }
}

solc.compile(..., findImports)
*/
//solc --optimize --bin Factory.sol | solc --link --libraries TestLib:drctlib.address
/*var linkedMetaCoinCode = metaCoinBytecode.replace(
  /_+TestLib_+/g,
  testLib.address.replace("0x", "")
);*/

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

    //factory = await linkedFactory.new();
	//tried removing deployer. and it did not work, also tried DRCTLibrary insteas of drctlib
	//deployer.link(drctlib,Factory);
	//factory = await Factory.new();