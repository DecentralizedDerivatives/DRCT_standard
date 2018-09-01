/**
*Checks the oracle value after the query was sent.
*Daily_1_OracleQuery_db.js has to be ran first.
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var _date = Date.now()/1000- (Date.now()/1000)%86400;

/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer(_master) specified.
*_nowUTC is only used to display a human readable date on the console.
*/

var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log("master", _nowUTC, _master);

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    sleep_s(30);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log("factory count", count);
    console.log("Factory_count, UTCtime, factory_address, oracle_address, value, link");
    sleep_s(30);
    try{
    for(i = 1; i <= count; i++){
        sleep_s(30);
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        //console.log("loop", i);
        sleep_s(60);
        let factory = await Factory.at(factory_address);
        //console.log("get factory", factory.address);
        sleep_s(30);
        let oracle_address = await factory.oracle_address.call();
        //console.log("get oracle address", oracle_address);
        sleep_s(60);
        if (oracle_address != '0x') {
        let oracle = await Oracle.at(oracle_address);
        //console.log("get oracle", oracle.address);
        sleep_s(30);
        var value =  await oracle.retrieveData(_date);
        //console.log("retreive oracle data", value);
        sleep_s(30);
        var value1= value/1000;
        var link = "".concat('<https://rinkeby.etherscan.io/address/',oracle_address,'>' );
        var api = await oracle.getusedAPI();
        sleep_s(30);
        var ar = [factory.address, oracle_address, _nowUTC,  value1, link, api];
        console.log(ar.join(', '));
        } else {
            //console.log("next factory");
        }
    }

    } catch(e) {
        console.error();
    }
}
