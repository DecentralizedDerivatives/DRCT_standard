/**
*
*update the factory with deprecated oracle with an existing oracle
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
var _oracle = "0x6be49e4e660aa759f468669b0a5696e73b537cb7";
var _factory = "0xa18e394d8de8f0203fa89b9f35212a2ecbede48a";



//BTC oracle
//var _oracle = "0x488adf792b598db87ff8af711d0f19601f31c3e7";
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
