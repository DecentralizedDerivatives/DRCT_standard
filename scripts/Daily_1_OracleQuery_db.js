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
var _master = "0xb9910c2269cb3953e4b4332ef6f782af97a4699f"; 
var _nowUTC  = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
console.log(_nowUTC);

//BTC oracle
var _oracleBtc = "0x488adf792b598db87ff8af711d0f19601f31c3e7";

//ETH oracle
var _oracleEth = "0x6be49e4e660aa759f468669b0a5696e73b537cb7";

module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
    console.log("Factory_count, UTCtime, factory_address, oracle_address, balance, link");
    
    let oracle = await Oracle.at(_oracleEth);
    await oracle.pushData();

    let oracle2 = await Oracle.at(_oracleBtc);
    await oracle2.pushData();

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
