
var MasterDeployer = artifacts.require("MasterDeployer")
var Oracle = artifacts.require("Oracle")
var _master = "0x300ac58f86804ea589102b93d27d9d7a2bb78255";


module.exports =async function(callback) {
      
    let masterDeployer = await MasterDeployer.at(_master);
    await masterDeployer.removeFactory("0xd898e32010bec9f21d9b55b51fac89cbdf746799");
    await masterDeployer.removeFactory("0xc298fde05a166d8af7cf1c805098234dfa2f0466");
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
    }

}