var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var _master = "0x300ac58f86804ea589102b93d27d9d7a2bb78255";
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);


module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
 
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        let factory = await Factory.at(factory_address);
        var balance;
        var wei;
        var numbal;
        web3.eth.getBalance(factory_address, function(error, wei) {
            var balance = web3.fromWei(wei, 'ether');
            var ar = [count, _nowUTC, factory_address,  balance];
            console.log(ar.join(', '));
            var numbal = balance.toNumber()-0;
            if (numbal > 0) {
                await factory.withdrawFees();
                console.log("Fees Withdrawn: ", numbal);
            } else {
                console.log("No fees to withdraw");
            } 
        });
  	}
}
