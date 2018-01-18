var Factory = artifacts.require("Factory");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');



module.exports =async function(callback) {
  let factory = await Factory.deployed();
  let long_token = await  ;
  let short_token = await ;
  var expiring_contracts = []
  //Get list of swaps to pay (end on certain start date)
  var count = await factory.getCount();
  for(i = 0; i <= count; i++){
    var add = await factory.contracs(i)
    var date =await factory.created_contracts(o_startdate);
    console.log(date, now.getDate());
    if (date == now.getDate()){
      expiring_contracts.push(add);
    }
  }
  console.log('There are ',expiring_contracts.length,' contracts with this end date');

  //Get number of token holders per swap
  console.log('There are X number of token holders for this contract');
  for(i = 0, i<= expiring_contracts.length,i++){
    var swap_add = expiring_contracts[i];
    swap = TokenToTokenSwap.at(swap_add);
    var address_count = await DRCT_Token.addressCount(swap_add);
      for (j = 1, j <= address_count){
        await swap.forcePay(j,j+20,{from:account_one});
        j += 20;
      }
  }
  console.log('All contracts successfully paid');

}
