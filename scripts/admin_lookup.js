/**
*Check which contracts expired and force pay them.
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var TokenToTokenSwap = artifacts.require("TokenToTokenSwap");
var DRCT_token = artifacts.require("DRCT_token");
var _date = Date.now()/1000- (Date.now()/1000)%86400;

/**
*@dev Update the Master Deployer contract. This will loop through each
*factory associated with the master deployer(_master) specified and each
*swap and force pay them.
*/

//var _master = "0x95b6cf3f13e34448d7c9836cead56bdd04a5941b"; //rinkeby
//var _master = "0xe8327b94aba6fbc3a95f7ffaf8dd568e6cd36616"; //rinkeby new dud
//var _master= "0x58f745e66fc8bb2307e8d73d7dafeda47030113c"; //mainnet
var _master= "0xcd8e11dad961dad43cc3de40df918fe808cbda74"; //maninnet new dud

module.exports =async function(callback) {
    let l_count;
    let l_token_owner;
    let s_count;
    let s_token_owner;

    let masterDeployer = await MasterDeployer.at(_master);
    sleep_s(30);
    var count = parseInt(await masterDeployer.getFactoryCount());
    sleep_s(10);
    console.log('There are',count,' total existing factories');
    if(count>0){
        for(i = 1; i <= count; i++){ //switch back j=2 to j=1*******************
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
        sleep_s(20);
        let factory = await Factory.at(factory_address);
        sleep_s(20);
        let swaps = await factory.getCount();
        console.log('Date', _date);


            let dtl = await factory.getDateCount();//dates to loop
            console.log("dtl", dtl);
            sleep_s(20);

            for(j = 0; j < dtl; j++){ 
        	    var tdate = await factory.startDates(j); 
                console.log("tdate", tdate);
         if (_date <= tdate) {       
        for(f = 0; f < swaps; f++){
            let swap_address = await factory.contracts.call(f);
            console.log('Swap Address',swap_address);
            let swap =await TokenToTokenSwap.at(swap_address);
            sleep_s(20);
            let variables = await swap.showPrivateVars();
            sleep_s(20);
            // [userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens,  duration,start_value, Start date, end_date, multiplier
            var startDate = variables[4];
            var endDate = variables[5];
            console.log('End Date: ', endDate);
            console.log('start Date: ', startDate);
                if (_date <= startDate){
                    var long_token_add =await factory.long_tokens(startDate);
                    var short_token_add =await factory.short_tokens(startDate);
                    var l_drct = await DRCT_token.at(long_token_add);
                    var s_drct = await DRCT_token.at(short_token_add);
                    var l_add_count = await l_drct.addressCount(long_token_add);
                    var s_add_count = await s_drct.addressCount(short_token_add);
                //counts[1] = counts[0] <= self.contract_details[7].add(_numtopay) ? counts[0] : self.contract_details[7].add(_numtopay).add(1);
                //Indexing begins at 1 for DRCT_Token balances
                    console.log("l_add_count", l_add_count);
                    console.log("long_token_add", long_token_add);
                    for (k=0; k <= l_add_count; k++) {
                        l_count, l_token_owner = await l_drct.getBalanceAndHolderByIndex(k, swap_address);
                        console.log("Long",l_count, l_token_owner)
                    }

                    console.log("s_add_count", s_add_count);
                    console.log("short_token_add", short_token_add);
                    for (m=0; m <= s_add_count; m++){
                        s_count, s_token_owner = await s_drct.getBalanceAndHolderByIndex(m, swap_address);
                        console.log("short",s_count, s_token_owner)
                    }
                }
            }

            }
        }
   }
}
}








