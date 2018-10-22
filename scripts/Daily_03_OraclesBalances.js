/**
*Send Oraclize query for the orales being used in each factory under
*the master deployer specified.
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");

/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer(_master) specified.
*_nowUTC is only used to display a human readable date on the console.
*/

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
//var _master = "0xe8327b94aba6fbc3a95f7ffaf8dd568e6cd36616"; //rinkeby new dud
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
var _master= "0xcd8e11dad961dad43cc3de40df918fe808cbda74"; //maninnet new dud
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);


module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    sleep_s(30);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
    console.log("Factory_count, UTCtime, factory_address, oracle_address, balance, link");
    sleep_s(30);
    
    for(i = 1; i <= count; i++){
        sleep_s(30);
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        sleep_s(30);        
        let factory = await Factory.at(factory_address);
        sleep_s(30);
        let oracle_address = await factory.oracle_address.call();
        sleep_s(30);
        var balance;
        var wei;
        var numbal;
            await web3.eth.getBalance(oracle_address, async function(error, wei) {
            if (!error) {
            var balance = web3.fromWei(wei, 'ether');
            sleep_s(30);
            var link = "".concat('<https://rinkeby.etherscan.io/address/',oracle_address,'>' );
            var ar = [count, _nowUTC, factory_address, oracle_address,  balance, link];
            console.log(ar.join(', '));
            var numbal = balance.toNumber()-0;
            //console.log(numbal)//this works
            }
          });

    }
}
