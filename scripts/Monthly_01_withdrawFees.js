/**
*@dev Use this to withdraw fees from Factories
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");

/**
*@dev Update the master deployer address (_master). This will loop through each
*factory associated with the master deployer(_master) specified and witdraw fees.
*/
//var _master = "0xb9910c2269cb3953e4b4332ef6f782af97a4699f";
var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
var _wrapped = "0x6248cb8a316fc8f1488ce56f6ea517151923531a"; //rinkeby
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
//var _wrapped = "0xf2740c75f221788cf78c716b953a7f1c769d49b9"; //mainnet
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    let wrappedEth = await Wrapped_Ether.at(_wrapped);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log("Factory_count, UTCtime, factory_address, value,fundsWithdrawn, link");

    for(i = 1; i <= count; i++){
        sleep_s(30);
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        sleep_s(30);        
        let factory = await Factory.at(factory_address);
        sleep_s(30);
        let factory_bal = await wrappedEth.balanceOf(factory_address);
        let oracle_address = await factory.oracle_address.call();
        sleep_s(60);
        if (oracle_address != '0x') {
            if (factory_bal > 0) {
                await factory.withdrawFees();
                        sleep_s(60);
                var fundsWithdrawn= 'Yes';
                        sleep_s(60);
            } else {
                var fundsWithdrawn= 'No';
            } 
        var link = "".concat('<https://rinkeby.etherscan.io/address/0x074993dee953f2706ae318e11622b3ee0b7850c3','>' );
        var ar = [count, _nowUTC, factory_address,  factory_bal, fundsWithdrawn, link];
        console.log(ar.join(', '));
        }   
  	}
}
