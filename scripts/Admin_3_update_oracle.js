/**
*Deploy new oracle with updated API information and 
*update the factory using deprecated oracle.
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

var _oracle_api = "json(https://api.gdax.com/products/ETH-USD/ticker).price";
var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price";
var _factory = "0xd47823a9769bec0bc31d3ef8b076d820865f39d0";

//var _oracle_api = "json(https://api.gdax.com/products/BTC-USD/ticker).price";
//var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price";
//var _factory = "0xb4dab81e95719ea69f08616c221e42489e84da3a";

module.exports =async function(callback) {
    let factory;
    let oracle;
    factory = await Factory.at(_factory);
    oracle = await Oracle.new(_oracle_api,_oracle_api2);
    await factory.setOracleAddress(oracle.address);
    console.log('Factory : ',factory.address);
    console.log('Oracle: ',oracle.address);
}
