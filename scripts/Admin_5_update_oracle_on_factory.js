/**
*
*update the factory using deprecated oracle with an existing oracle
*/
var MasterDeployer = artifacts.require("MasterDeployer");
var Oracle = artifacts.require("Oracle");
var Factory = artifacts.require("Factory");

/**
*@dev Current Oracle API's that can be used for BTC/USD or ETH/USD:
* "json(https://api.gdax.com/products/BTC-USD/ticker).price"
* "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
* "json(https://api.gdax.com/products/ETH-USD/ticker).price"
* "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
*
*Update oracle APIs(two are needed, the second one is used as backup)
*/
//ETH oracle
var _oracle = "0xf5b3b07568b0e90df92df0a22f955a7219077289";
var _factory = "0xa18e394d8de8f0203fa89b9f35212a2ecbede48a";



//BTC oracle
//var _oracle = " 0xb7e4411299161051bdae859392537d367758a62a";
//var _factory = "0x5dbc9e739bcc518c4ce3084e597117eb0dc929e6";

module.exports =async function(callback) {
    let factory;
    //let oracle;
    factory = await Factory.at(_factory);
    //oracle = await Oracle.at(_oracle);
    await factory.setOracleAddress(_oracle);
    console.log('Factory : ',factory.address);
    console.log('Oracle: ',_oracle);
}
