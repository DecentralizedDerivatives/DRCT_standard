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
var _master = "0xb9910c2269cb3953e4b4332ef6f782af97a4699f"; 


module.exports =async function(callback) {
    var swaps;
    let ltoken;
    let stoken;

    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('Factories count:',count);

    var t_expiring_contracts = [];
    var t_paid_contracts = [];
    var t_npaid_contracts = [];
    var t_started_contracts = [];
    var t_created_contracts = [];
    var t_short_holders = [];
    var t_long_holders = [];
    var total_holders_all = [];


try{
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
        var npaid_contracts = [];
        var started_contracts = [];
        var created_contracts = [];
        try{
            for(j = 1; j <= swaps; j++){
                var swap_address = await factory.contracts(j);
                var date =await factory.created_contracts(swap_address);
                date = (date === undefined) ? 0 : date;
                date = parseInt(date);

                now = await Date.now()/1000 - 7*86400 - (Date.now()/1000)%86400;
                console.log("Swap_Address",swap_address);
                console.log("Date", date);

                if (date > 0) {

                    let swap =await TokenToTokenSwap.at(swap_address);
                    var swap_state = await swap.currentState();
                    swap_state = (swap_state === undefined) ? 0 : swap_state;
                    if (isNaN(swap_state.toNumber())){
                        swap_state = 0;
                    }
                    console.log("current swap state", swap_state)

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
                        //if (isNaN(address_countl.toNumber())){
                          //  address_countl = 0;
                        //}
                        let l = address_countl.toNumber();
                        t_long_holders.push(l);
                        console.log('Long_token_holders:', address_countl.toNumber());
            
                    } else{
                        address_counts = await stoken.addressCount(swap_address);
                        //if (isNaN(address_counts.toNumber())){
                        //    address_counts = 0;
                        //}
                        let s= address_counts.toNumber();
                        t_short_holders.push(s);
                        console.log('Short_token_holders:', address_counts.toNumber());
                    }
                }
                var total_holders = address_counts.toNumber() + address_countl.toNumber();
                console.log("Total_holders for the swap:", total_holders);
    


                    //number of contracts expiring today
                    if (date - now + 86400 == 0){
                        expiring_contracts.push(swap_address);
                        t_expiring_contracts.push(swap_address);
                    }
            
                    //number of contracts/swaps expiring today that were paid out or their current state=3
                    if (date - now + 86400 == 0 && swap_state == 3){
                        paid_contracts.push(swap_address);
                        t_paid_contracts.push(swap_address);
                    }

                    if (date - now + 86400 == 0 && swap_state == 2){
                        npaid_contracts.push(swap_address);
                        t_npaid_contracts.push(swap_address);
                    }


                    //number of open/started contracts/swaps current state=2
                    if (date > 0 && swap_state == 2){
                        started_contracts.push(swap_address);
                        t_started_contracts.push(swap_address);
                    }


                    //number of created contracts/swaps current state=1
                    if (date > 0 && swap_state == 1){
                        created_contracts.push(swap_address);
                        t_created_contracts.push(swap_address);
                    }




                } else if (date == 0 ) {
                    throw "noSwapStarted";
                }

            console.log('Swaps expiring today:',expiring_contracts.length); 
            console.log('Swaps expiring today that were paid out:',paid_contracts.length);
            console.log('Swaps expiring today that have not been paid out:',npaid_contracts.length);
            console.log('Started_contracts:',started_contracts.length);
            console.log('Created_contracts:', created_contracts.length);


            } //swap loop



            } catch(e) {
                console.error();
            }

        } //factory loop
        console.log("Totals for all factories");
        console.log('Total Swaps expiring today:',t_expiring_contracts.length); 
        console.log('Total Swaps expiring today that were paid out:',t_paid_contracts.length);
        console.log('Total Swaps expiring today that have not been paid out:',t_npaid_contracts.length);
        console.log('Total Started_contracts:',t_started_contracts.length);
        console.log('Total Created_contracts:', t_created_contracts.length);
        var sum_long = t_long_holders.reduce(function(a, b) { return a + b; }, 0);
        var sum_short = t_short_holders.reduce(function(a, b) { return a + b; }, 0);
        console.log("Total long holders", sum_long);
        console.log("Total short holders", sum_short);
        console.log("Total long", t_long_holders);
        console.log("Total short", t_short_holders);


        } catch(e) {
            console.error();
        }
}



 