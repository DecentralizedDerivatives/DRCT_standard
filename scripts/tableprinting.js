
var Factory = artifacts.require("Factory");
var Exchange = artifacts.require("Exchange");
const DRCT_Token = artifacts.require('./DRCT_Token.sol');


module.exports =async function(callback) {
      //Open Dates
       let factory = await Factory.deployed();
       var numDates = await factory.getDateCount();
       var openDates = []
       for(i=0;i<numDates;i++){
            openDates.push(await factory.startDates.call(i))
       }
      //orderbook

      let exchange = await Exchange.deployed();
      //first get number of open books (tokens with open orders):
      var numBooks = await exchange.getBookCount();
      //get orders for that book:
      var orderbook = []
      for(i=0;i<numbBooks;i++){
            var orders = await exchange.getOrders(await exchange.openBooks(i));
            for(j=0;j<orders.length;j++){
                  order = await exchange.getOrder(orders[j])
                  console.log(order);
                  orderbook.push(order);
                  //order contains the party, price, amount, token address
            }
      }
      


      //my portfolio
      var myTokens = [];
      var myBalances = [];
      for(i=0;i<openDates.length;i++){
            var tokens = await factory.getTokens(openDates[i]);
            var longtoken = await DRCT_Token.at(tokens[0]);
            var shorttoken = await DRCT_Token.at(tokens[1]);
            var longbalance = await longtoken.balanceOf(accounts[0]);
            if(longbalance > 0){
                  myTokens.push(tokens[0])
                  myBalances.push(longbalance)
            }
            var shortbalance = await shorttoken.balanceOf(accounts[0])
            if(shortbalance > 0){
                  myTokens.push(tokens[0])
                  myBalances.push(shortbalance)
            }
      }
      //contract details
      var details = await factory.getVariables();
      //details is: oracle_address, duration, multiplier



}