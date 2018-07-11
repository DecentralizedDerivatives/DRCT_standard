/**
*@dev Use this to withdraw fees from Factories
*/
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");

/**
*@dev Update the master deployer address (_master). This will loop through each
*factory associated with the master deployer(_master) specified and witdraw fees.
*/
var _master = "0x300ac58f86804ea589102b93d27d9d7a2bb78255";
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log("Factory_count, UTCtime, factory_address, value,fundsWithdrawn, link");

    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        let factory = await Factory.at(factory_address);
        var balance;
        var wei;
        var numbal;
        web3.eth.getBalance(factory_address, function(error, wei) {
            var balance = web3.fromWei(wei, 'ether');
            var numbal = balance.toNumber()-0;
        });
        //    if (numbal > 0) {
                await factory.withdrawFees();
                var fundsWithdrawn= 'Yes';
        //    } else {
        //        var fundsWithdrawn= 'No';
        //    } 
            var link = "".concat('<https://rinkeby.etherscan.io/address/',factory_address,'>' );
        //    var ar = [count, _nowUTC, factory_address,  numbal, fundsWithdrawn, link];
        //    console.log(ar.join(', '));
        
  	}
}
