/**
*Send Oraclize query for the orales being used in each factory under
*the master deployer specified.
*/
var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");

/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer(_master) specified.
*_nowUTC is only used to display a human readable date on the console.
*/
//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
var _master = "0xe8327b94aba6fbc3a95f7ffaf8dd568e6cd36616"; //rinkeby new dud
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
//var _master= "0xcd8e11dad961dad43cc3de40df918fe808cbda74"; //maninnet new dud

var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);

//BTC oracle
//var _oracleBtc = "0x488adf792b598db87ff8af711d0f19601f31c3e7";
var _oracleBtc = "0x98cb5fc6ce37b4c4dceab510a56af254c551b705"; //new
//var  _oracleBtc= "0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34"; //mainnet

//ETH oracle
//var _oracleEth = "0x6be49e4e660aa759f468669b0a5696e73b537cb7";
var _oracleEth = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//new
//var _oracleEth = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//mainnet

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
    console.log("Factory_count, UTCtime, factory_address, oracle_address, balance, link");
    
    let oracle = await Oracle.at(_oracleEth);
    await oracle.pushData();
    console.log("Oracle Eth pushed");

    let oracle2 = await Oracle.at(_oracleBtc);
    await oracle2.pushData();
    console.log("Oracle Btc pushed");

    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        let factory = await Factory.at(factory_address);
        let oracle_address = await factory.oracle_address.call();
        var balance;
        var wei;
        var numbal;
            await web3.eth.getBalance(oracle_address, async function(error, wei) {
            if (!error) {
            var balance = web3.fromWei(wei, 'ether');
            var link = "".concat('<https://rinkeby.etherscan.io/address/',oracle_address,'>' );
            var ar = [count, _nowUTC, factory_address, oracle_address,  balance, link];
            console.log(ar.join(', '));
            var numbal = balance.toNumber()-0;
            //console.log(numbal)//this works
            }
          });
        
        //console.log(numbal, "numbal");//this doesn't work
        //console.log(balance, "balance");//this doesn't work
        //console.log(wei, "wei");//this doesn't work
            //if (numbal != 0) {
            //    let oracle = await Oracle.at(oracle_address);
            //    await oracle.pushData();
            //   console.log("Oracle is funded, query sent successfully");
            //  } else {
             //   console.log("Funding Oracle");
             //   let oracle = await Oracle.at(oracle_address);
             //   await oracle.fund({value: web3.toWei(.25,'ether')});
             //   await oracle.pushData();
             //   console.log("Query sent successfully, after funding");
            //} 

            //wait some time
            //get transaction hash with something like this
            //var receipt = await value.logs.transactionHash;
            //console.log(receipt);
            //var tx = receipt.logs.transactionHash;
            //console.log(tx);
            //
  	}
}
