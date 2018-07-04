var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var _date = Date.now()/1000- (Date.now()/1000)%86400;
var _master = "0x300ac58f86804ea589102b93d27d9d7a2bb78255";
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log("Factory_count, UTCtime, factory_address, oracle_address, value");

    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        let factory = await Factory.at(factory_address);
        let oracle_address = await factory.oracle_address.call();
        let oracle = await Oracle.at(oracle_address);
 		var value =  await oracle.retrieveData(_date);
        var value1= value/1000;
        var link = "".concat('<https://rinkeby.etherscan.io/address/',oracle_address,'>' );
        var ar = [count, _nowUTC, factory_address, oracle_address,  value1, link];
        console.log(ar.join(', '));
        
  	}
}
