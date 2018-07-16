/**
*Daily summary.
*/
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var TokenToTokenSwap = artifacts.require("TokenToTokenSwap");
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var _date = Date.now()/1000- (Date.now()/1000)%86400;

/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer and provide a summary.
*/
var _master = "0xfce97feb873355d43e9102bbef83a1ed758edddf"; 

module.exports =async function(callback) {
    var swaps;
    let ltoken;
    let stoken;

    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('Factories count:',count);

    //Total swaps expiring by factory
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        let factory = await Factory.at(factory_address);
        let oracle_address = await factory.oracle_address.call();
        var swaps = await factory.getCount();
        if (isNaN(swaps.toNumber())){
         swaps = 0;
        }
        console.log('Oracle Address:', oracle_address);
        console.log('Factory Address:',factory_address);
        console.log('Swaps count:',swaps);

        var expiring_contracts = [];
        var paid_contracts = [];
        var started_contracts = [];
        var created_contracts = [];
            var swap_address = await factory.contracts(i)


            var date =await factory.created_contracts(swap_address);
            date = parseInt(date);
            now = await Date.now()/1000 - 7*86400 - (Date.now()/1000)%86400;
            console.log("Swap_Address",swap_address);
            console.log("Date", date);

            //number of contracts expiring today
            if (date - now + 86400 == 0){
                expiring_contracts.push(swap_address);
            }
            console.log('Swaps expiring today:',expiring_contracts.length); 

            //number of contracts/swaps expiring today that were paid out or their current state=3
            let swap =await TokenToTokenSwap.at(swap_address);
            let swap_state = await swap.currentState();
            if (date - now + 86400 == 0 && swap_state == 3){
                paid_contracts.push(swap_address);
            }
            console.log('Swaps expiring today that were paid out:',paid_contracts.length);

            //number of open/started contracts/swaps current state=2
            if (date > 0 && swap_state == 2){
                started_contracts.push(swap_address);
            }
            console.log('Started_contracts:',started_contracts.length);

            //number of created contracts/swaps current state=1
            if (date > 0 && swap_state == 1){
                created_contracts.push(swap_address);
            }
            console.log('Created_contracts:', created_contracts.length);

            //Get number of token holders per swap
            if (date > 0){
                swap = TokenToTokenSwap.at(swap_address);
                long_token_add =await factory.long_tokens(date);
                short_token_add =await factory.short_tokens(date);
                ltoken = await DRCT_Token.at(long_token_add);
                stoken = await DRCT_Token.at(short_token_add);
                for(k=0;k<=1;k++){
                    var address_countl;
                    var address_counts;
                    if(k == 0){
                        address_countl = await ltoken.addressCount(swap_address);
                        console.log('Long_token_holders:', address_countl.toNumber());
                    } else{
                        address_counts = await stoken.addressCount(swap_address);
                        console.log('Short_token_holders:', address_counts.toNumber());
                    }
                }
                var total_holders = address_counts.toNumber() + address_countl.toNumber();
                console.log("Total_holders:", total_holders)
            }
        }
    }


 