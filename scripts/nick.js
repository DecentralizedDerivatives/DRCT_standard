/**
Use this to create new tokens
*/



var add1 = "0xc69c64c226fEA62234aFE4F5832A051EBc860540"

module.exports =async function(callback) {
      web3.eth.getBalance(add1, function (error, result) {
        if (!error) {
          console.log(add1 + ': ' + result);
        };
      });
}

