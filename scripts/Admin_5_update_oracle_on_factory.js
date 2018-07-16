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
var _oracle = "0xf0d3fdb12f118ed3f64c6f0c373365ae21849206";
var _factory = "0xdfb380afc0948e9551fd17b486681122b5936c2a";



//BTC oracle
//var _oracle = "0xf6d293faa7321d671b24a3a6abb224b1b1aaefde";
//var _factory = "0x95c9c47558115b12f25dce5103e73e0803a5b9c7";

module.exports =async function(callback) {
    let factory;
    //let oracle;
    factory = await Factory.at(_factory);
    //oracle = await Oracle.at(_oracle);
    await factory.setOracleAddress(_oracle);
    console.log('Factory : ',factory.address);
    console.log('Oracle: ',_oracle);
}
