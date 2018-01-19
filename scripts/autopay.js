var Factory = artifacts.require("Factory");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');



module.exports =async function(callback) {
  let factory = await Factory.deployed();
  let ltoken;
  let stoken;
  var expiring_contracts = []
  //Get list of swaps to pay (end on certain start date)
  var count = parseInt(await factory.getCount());
  for(i = 0; i < count; i++){
    var add = await factory.contracts(i)
    var date =await factory.created_contracts(add);
    date = parseInt(date);
    long_token_add =await factory.long_tokens(date);
    short_token_add =await factory.short_tokens(date);
    now = Date.now()/1000 - (Date.now()/1000)%86400;
    console.log(date - now + 86400);
    console.log(date, now - 86400);
    if (date - now + 86400 == 0){
      expiring_contracts.push(add);
    }
  }
  console.log('There are ',expiring_contracts.length,' contracts with this end date');

  //Get number of token holders per swap
  for(i = 0; i< expiring_contracts.length;i++){
    var swap_add = await expiring_contracts[i];
    console.log(swap_add);
    swap = TokenToTokenSwap.at(swap_add);
    ltoken = DRCT_Token.at(long_token_add);
    stoken = DRCT_Token.at(short_token_add);
    for(k=0;k<=1;k++){
      var address_count;
      if(k == 0){
        address_count = await ltoken.addressCount(swap_add);
      }
      else{
        address_count = await stoken.addressCount(swap_add);
      }
      address_count = parseInt(address_count);
      console.log('There are', address_count,' number of token holders for this contract');
        for (j = 1; j <= address_count; j+=20){
          await swap.forcePay(j,j+20);
          console.log('Swap add paid:',swap_add);
        }
    }
  }
  console.log('All contracts successfully paid');
}
