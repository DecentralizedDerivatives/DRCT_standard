var Oracle = artifacts.require("./Oracle.sol");
var Test_Oracle = artifacts.require("./Test_Oracle.sol");

module.exports = function(deployer){
  deployer.deploy(Oracle,"https://api.gdax.com/products/BTC-USD/ticker).price", "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price");
  deployer.deploy(Test_Oracle,"https://api.gdax.com/products/BTC-USD/ticker).price");
}