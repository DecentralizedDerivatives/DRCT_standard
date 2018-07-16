/**
*Use this to remove deprecated factories
*/
var MasterDeployer = artifacts.require("MasterDeployer");
var Oracle = artifacts.require("Oracle");

/**
*@dev Update the Master Deployer Address that corresponds to the factory you 
*want to remove. If you need to remove multiple factories from the same deployer you
*can include similar code to this and specify the factory as a string. 
*await masterDeployer.removeFactory("0xd898e32010bec9f21d9b55b51fac89cbdf746799");
*
*If you have to delete factories from different Master Deployers 
*you will need to run this code each time you need to update the Master Deployer.
*/

var _master ="0xfce97feb873355d43e9102bbef83a1ed758edddf"; //two api oracle
var _factory= " ";//enter factory address to remove


module.exports =async function(callback) {
      
    let masterDeployer = await MasterDeployer.at(_master);
    await masterDeployer.removeFactory(_factory);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
    }
}
