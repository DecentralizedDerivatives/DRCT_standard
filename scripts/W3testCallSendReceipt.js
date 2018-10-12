const Web3 = require('web3');
require('dotenv').config()
var HDWalletProvider = require("truffle-hdwallet-provider");

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var mnemonic = process.env.ETH_MNEMONIC;
var accessToken = process.env.INFURA_ACCESS_TOKEN;
//const web3 = getWeb3;
//var  web3 = new Web3("https://rinkeby.infura.io/"+ accessToken);

var web3 = new Web3(web3.currentProvider);
var web3 = new Web3(new HDWalletProvider(mnemonic,"https://rinkeby.infura.io/"+ accessToken));
var accountFrom= '0xc69c64c226fea62234afe4f5832a051ebc860540';
/*var accountFrom = web3.eth.getAccounts().call((function(error, result){
    if (!error)
        console.log(result);
}));
console.log(accountFrom);*/
var gas_Price= 4000000000;
var gas_Limit= 4700000;

var Factory = artifacts.require("Factory");
var factoryAbi = Factory.abi;
var factoryByte = Factory.bytecode;


var swapFee = 0; //.05% = 500
//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby
var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// rinkeby btc
//var _factoryEth = "0xf55e6ce774cec3817467aed5f5a5769f006658d0";// rinkeby eth

//var _factoryDud = "0xa58d1ea78cd1b610d5dc08c57b1f9fea185061cd"; //MAINNET
//var _factoryBtc = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43";// Mainnet btc
//var _factoryEth = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a";// Mainnet eth
//gas: gas_Limit, gasPrice: gas_Price



module.exports =async function(callback) {

/*let accountFrom = await web3.eth.getAccounts();
console.log(accountFrom);*/
var factory = await new web3.eth.Contract(factoryAbi,_factoryBtc);
console.log(factory.methods);
console.log(factory.options.address);
console.log(_factoryBtc);
await factory.methods.getVariables().call().then(console.log);
await factory.methods.setSwapFee(0).send({from: accountFrom,gas: gas_Limit,gasPrice: gas_Price })
.on('transactionHash', function(hash){
    console.log(hash);
})
.on('receipt', function(receipt){
    // receipt example
    console.log(receipt);
})
.on('confirmation', function(confirmationNumber, receipt){
    console.log(confirmationNumber);
})

.on('error', console.error); // If there's an out of gas error the second parameter is the receipt.
;

}

/*function getWeb3() {
	const myWeb3 = new Web3(web3.currentProvider);
	return myWeb3;
}*/

/*let contract = Contract(artifacts);
contract.setProvider(web3.currentProvider);
//dirty hack for web3@1.0.0 support for localhost testrpc, see https://github.com/trufflesuite/truffle-contract/issues/56#issuecomment-331084530
if (typeof contract.currentProvider.sendAsync !== "function") {
  contract.currentProvider.sendAsync = function() {
    return contract.currentProvider.send.apply(
      contract.currentProvider, arguments
    );
  };
}*/