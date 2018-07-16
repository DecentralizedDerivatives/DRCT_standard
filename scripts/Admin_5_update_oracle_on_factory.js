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
var _oracle = "0x08d41820d5ec978b5e24932ef597ccb6052c7283";
var _factory = "0x1cd5f586f2abc85b022e8cd19c67814f47af9da2";



//BTC oracle
//var _oracle = "0xb0c662507e64951d820c718a3cebc4a4eedaa1af";
//var _factory = "0x1ca651f77085e79bc4b34477825d6dcf664ed8fa";

module.exports =async function(callback) {
    let factory;
    //let oracle;
    factory = await Factory.at(_factory);
    //oracle = await Oracle.at(_oracle);
    await factory.setOracleAddress(_oracle);
    console.log('Factory : ',factory.address);
    console.log('Oracle: ',_oracle);
}
