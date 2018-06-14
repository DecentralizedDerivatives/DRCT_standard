var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var _date = Date.now()/1000- (Date.now()/1000)%86400;
 var _master = "0x300ac58f86804ea589102b93d27d9d7a2bb78255";


module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
 
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
        let factory = await Factory.at(factory_address);
        let oracle_address = await factory.oracle_address.call();
        console.log('Oracle Address:', oracle_address);
     let oracle = await Oracle.at(oracle_address);
 		  var value =  await oracle.retrieveData(_date);
      console.log('Oracle result -',value);
  	}
}
