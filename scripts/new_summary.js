/**
*Daily summary.
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

var MasterDeployer = artifacts.require("MasterDeployer");
var Wr = Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var TokenToTokenSwap = artifacts.require("TokenToTokenSwap");
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var _date = Date.now()/1000- (Date.now()/1000)%86400;
var web3 = require('web3').web3;

/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer and provide a summary.
*/

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
var _master = "0xe8327b94aba6fbc3a95f7ffaf8dd568e6cd36616"; //rinkeby new dud
var _wrapped= "0x6248cb8a316fc8f1488ce56f6ea517151923531a";//rinkeby new dud
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
//var _master= "0xcd8e11dad961dad43cc3de40df918fe808cbda74"; //maninnet new dud
//var _wrapped= "0xf2740c75f221788cf78c716b953a7f1c769d49b9";//mainnet



module.exports =async function(callback) {
    var swaps;
    let ltoken;
    let stoken;

    let wrapped = await Wrapped_Ether.at(_wrapped);
    console.log("wrappped ether");
    let wrappedEth = await wrapped.totalSupply();
    console.log("wrppedEth supply", wrappedEth);
    sleep_s(30);
    let masterDeployer = await MasterDeployer.at(_master);
    console.log("master deployer");
    sleep_s(30);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('Factories count:',count);
    sleep_s(30);

    var t_short_holders = [];
    var t_long_holders = [];
    var total_holders_all = [];


try{
    
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        sleep_s(10);
        let factory = await Factory.at(factory_address);
        sleep_s(10);
        let oracle_address = await factory.oracle_address.call();
        sleep_s(20);
        if (oracle_address != '0x') {
            var swaps = await factory.getCount();
            sleep_s(10);
            if (isNaN(swaps.toNumber())){
            swaps = 0;
        }
        
        console.log('Oracle Address:', oracle_address);
        console.log('Factory Address:',factory_address);
        console.log('Swaps count:',swaps);

        var expiring_contracts = [];
        var paid_contracts = [];
        var npaid_contracts = [];
        var started_contracts = [];
        var created_contracts = [];
        try{
            //loop for swaps
            for(j = 0; j <= swaps; j++){
                var swap_address = await factory.contracts(j);
                console.log("swap address", swap_address);
                sleep_s(10);
                var date = await factory.created_contracts(swap_address);
                console.log(date);
                sleep_s(10);
                date = (date === undefined) ? 0 : date;
                date = parseInt(date);

                
                console.log("Swap_Address",swap_address);
                console.log("Date", date);

                if (date >= 0) {

                    let swap =await TokenToTokenSwap.at(swap_address);
                    sleep_s(10);
                    var swap_state = await swap.currentState();
                    sleep_s(10);
                    swap_state = (swap_state === undefined) ? 0 : swap_state;
                    if (isNaN(swap_state.toNumber())){
                        swap_state = 0;
                    }
                    console.log("current swap state", swap_state)

                    swap = TokenToTokenSwap.at(swap_address);
                    long_token_add =await factory.long_tokens(date);
                    sleep_s(10);
                    short_token_add =await factory.short_tokens(date);
                    sleep_s(10);
                    ltoken = await DRCT_Token.at(long_token_add);
                    sleep_s(10);
                    stoken = await DRCT_Token.at(short_token_add);
                    sleep_s(10);

                    for(k=0;k<=1;k++){
                    var address_countl;
                    var address_counts;
                    
                    if(k == 0){

                        console.log("long address", long_token_add);
                        let lnTx = await web3.eth.getTransactionCount(long_token_add);
                        console.log(lnTx);
                        address_countl = await ltoken.addressCount(swap_address);
                        let l = address_countl.toNumber();
                        console.log("address count", address_countl);
                        for(m=0;m<=l;m++){
                            userInfor = await ltoken.getBalanceAndHolderByIndex(m,swap_address);
                            console.log("long user amount, owner",userInfor);
                            /*if (userInfor != [0, '0x']) {
                                bal = await ltoken.balanceOf(alert(userInfor[1]));
                                console.log("balanceof", bal);
                            }*/
                        }
                        //if (isNaN(address_countl.toNumber())){
                          //  address_countl = 0;
                        //}
                        
                        t_long_holders.push(l);
                        console.log('Long_token_holders:', address_countl.toNumber());
            
                    } else{
                        console.log("short address", short_token_add);
                        address_counts = await stoken.addressCount(swap_address);
                        let s= address_counts.toNumber();
                        for(n=0;n<=s;n++){
                            userInfors = await stoken.getBalanceAndHolderByIndex(n,swap_address);
                            console.log("short user amount, owner",userInfor);
                            /*if (userInfors != [0, '0x']) {
                                sbal = await stoken.balanceOf(alert(userInfor[1]));
                                console.log("balanceof", sbal);
                            }*/
                        }
                        //if (isNaN(address_counts.toNumber())){
                        //    address_counts = 0;
                        //}
                        
                        t_short_holders.push(s);
                        console.log('Short_token_holders:', address_counts.toNumber());
                    }
                }

           
                    var total_holders = l + s;
                    console.log("Total_holders for the swap:", total_holders);

                } else /*if (date == 0 )*/ {
                    throw "noSwapStarted";
                }

    
            } //swap loop


            } catch(e) {
                console.error();
            }
        }
        
        } //factory loop

        var sum_long = t_long_holders.reduce(function(a, b) { return a + b; }, 0);
        var sum_short = t_short_holders.reduce(function(a, b) { return a + b; }, 0);


    } catch(e) {
        console.error();
    }

}


//calc percent change of oracle price from start date to end date
//how much was paid? does it match
 