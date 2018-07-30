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
var json = artifacts.require("./build/contracts/compiled.json");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");
var solc = require('solc');

const Web3 = require("web3");
const fs = require('fs');
const Tx = require('ethereumjs-tx')
const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/zkGX3Vf8njIXiHEGRueB"));
var address = process.argv[4];
var abi = json.abi;

//tried changing deployer to callback-did not work
module.exports =async function(deployer) {
	//console.log(Factory);
	//console.log(DRCTLibrary);
	var factoryByte = await fs.readFileSync('./build/contracts/Factory.json').toString().bytecode;
	//console.log(factoryByte);
	let drctlib;
	let factory;
	drctlib = await DRCTLibrary.new();
	console.log("DRCTLibrary", drctlib.address);
    var linkedFactory = await String(factoryByte).replace(/_+DRCTLibrary_+/g, drctlib.address.replace("0x", ""));
    //console.log(linkedFactory);    
    fs.writeFile('./build/contracts/compiled.json', JSON.stringify(linkedFactory), function(err) {
        if (err) throw err;
        console.log('Compiled & saved');
    });

//factory = await Compiled.new();
//console.log(factory.address);
var address = process.argv[4];
var abi = json.abi;
  web3.eth.getTransactionCount(account, function (err, nonce) {
    
    var data = web3.eth.contract(abi).at(address);
    console.log(data);

    var tx = new Tx({
      nonce: nonce,
      gasPrice: web3.toHex(web3.toWei('20', 'gwei')),
      gasLimit: 4000000,
      to: address,
      value: 0,
      data: data,
    });
    var raw = '0x' + tx.serialize().toString('hex');
    web3.eth.sendRawTransaction(raw, function (err, transactionHash) {
       console.log(transactionHash);
    });
  });
}


/*

tokencontract.new({data: linkedFactory.bytecode}).send({from: Owneraddress, 
gas:4700000}).on('confirmation', function(confirmationNumber, receipt){ 
console.log(confirmationNumber); tokencontract.options.address = 
receipt.contractAddress; }).on('receipt', function(receipt)
{console.log(receipt)})*/



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

abi = JSON.parse(compiledCode.contracts['auction.sol:ContractName'].interface);
bytecode = compiledCode.contracts['auction.sol:ContractName'].bytecode;
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


// Compile the source code
/*const input = fs.readFileSync('Token.sol');
const output = solc.compile(input.toString(), 1);
const bytecode = output.contracts['Token'].bytecode;
const abi = JSON.parse(output.contracts['Token'].interface);
*/
// Contract object
/*const contract = web3.eth.contract(abi);
*/
// Deploy contract instance
/*const contractInstance = contract.new({
    data: '0x' + bytecode,
    from: web3.eth.coinbase,
    gas: 90000*2
}, (err, res) => {
    if (err) {
        console.log(err);
        return;
    }*/

    // Log the tx, you can explore status with eth.getTransaction()
 //   console.log(res.transactionHash);

    // If we have an address property, the contract was deployed
/*    if (res.address) {
        console.log('Contract address: ' + res.address);
        // Let's test the deployed contract
        testContract(res.address);
    }
});*/