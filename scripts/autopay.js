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
  console.log('There are',count,' total contracts in this factory');
  for(i = 0; i < count; i++){
    var add = await factory.contracts(i)
    var date =await factory.created_contracts(add);
    date = parseInt(date);
    now = await Date.now()/1000 - 7*86400 - (Date.now()/1000)%86400;
    if (date - now + 86400 == 0){
      expiring_contracts.push(add);
    }
  }
  console.log('There are ',expiring_contracts.length,' contracts with this end date');

  //Get number of token holders per swap
  for(i = 0; i <= count; i++){
    var swap_add = await factory.contracts(i)
    var date =await factory.created_contracts(swap_add);
    if (date > 0){
      swap = TokenToTokenSwap.at(swap_add);
      long_token_add =await factory.long_tokens(date);
      short_token_add =await factory.short_tokens(date);
      ltoken = await DRCT_Token.at(long_token_add);
      stoken = await DRCT_Token.at(short_token_add);
      for(k=0;k<=1;k++){
        var address_countl;
        var address_counts
        if(k == 0){
          address_countl = await ltoken.addressCount(swap_add);
           console.log('There are', address_countl.toNumber(),'long token holders for this contract');
        }
        else{
          address_counts = await stoken.addressCount(swap_add);
           console.log('There are', address_counts.toNumber(),' short token holders for this contract');
        }
        var address_count = (parseInt(address_countl) > parseInt(address_counts) ? parseInt(address_countl) : parseInt(address_counts))
        for (j = 1; j <= address_count; j+=20){
          console.log((parseInt(date)), now);
            if ((await swap.current_state.call()) > 2  && (await swap.current_state.call()) < 5 && (parseInt(date))< now){
              await swap.forcePay(j,j+20);
              console.log('Swap add paid:',k,' ',swap_add);
            }
        }
      }
    }
  }
  console.log('All contracts successfully paid');
  var starting_contracts = {}
    for(i = 0; i < count; i++){
      var add = await factory.contracts(i)
      var date =await factory.created_contracts(add);
      date = parseInt(date);
      if (isNaN(starting_contracts[date.toString()])){
        starting_contracts[date.toString()] = 0;
      }
      if (date > 0){
        starting_contracts[date.toString()] +=  1;
      }
    }
  console.log(starting_contracts);

}
