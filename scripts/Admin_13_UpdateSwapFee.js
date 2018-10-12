/**
*This updates the swapFee
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var Factory = artifacts.require("Factory");

/**
*@dev Update the swapFee 
*
*/
var swapFee = 0; //.05% = 500

//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby
var _factoryBtc = "0x92217550aba5912ba7eb70978871daf7d6bcc16d";// rinkeby btc
var _factoryEth = "0xf55e6ce774cec3817467aed5f5a5769f006658d0";// rinkeby eth

//var _factoryDud = "0xa58d1ea78cd1b610d5dc08c57b1f9fea185061cd"; //MAINNET
//var _factoryBtc = "0xce971acf8b9b0ce67a8018c4af2094b02c22da43";// Mainnet btc
//var _factoryEth = "0x8ff7e9f04fed4a6d7184962c6c44d2e701c2fb8a";// Mainnet eth


module.exports =async function(callback) {
    let factory;
    let factory2;

    factory = await Factory.at(_factoryBtc);
    sleep_s(10);
    await factory.setSwapFee(swapFee);
    sleep_s(30);
    factory2 = await Factory.at(_factoryEth);
    sleep_s(10);
    await factory2.setSwapFee(swapFee);
    
    console.log("Type, Factory, swapFee")
    var  ar = ["Btc",factory.address, swapFee];
    var  ar2 = ["Eth",factory2.address, swapFee];
    console.log(ar.join(', '));
    console.log(ar2.join(', '));
        
}




