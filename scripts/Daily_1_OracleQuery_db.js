var Oracle = artifacts.require("Oracle");
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
        let oracle_address = await factory.oracle_address.call();
        var balance;
        var wei;
        var numbal;
        web3.eth.getBalance(oracle_address, function(error, wei) {
            var balance = web3.fromWei(wei, 'ether');
            var ar = [count, _nowUTC, factory_address, oracle_address,  balance];
            console.log(ar.join(', '));
            var numbal = balance.toNumber()-0;
            //console.log(numbal)
        });
            if (numbal != 0) {
                let oracle = await Oracle.at(oracle_address);
                await oracle.pushData();
                console.log("Oracle is funded, query sent successfully");
            } else {
                console.log("Funding Oracle");
                //await oracle.fund({value: web3.toWei(.25,'ether')});
                //let oracle = await Oracle.at(oracle_address);
                //await oracle.pushData();
                console.log("Query sent successfully, after funding");
            } 

            //wait some time
            //get transaction hash with something like this
            //var receipt = await value.logs.transactionHash;
            //console.log(receipt);
            //var tx = receipt.logs.transactionHash;
            //console.log(tx);
            //
  	}
}
