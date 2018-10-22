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

    let masterDeployer = await MasterDeployer.at(_master);
    sleep_s(30);
    var count = parseInt(await masterDeployer.getFactoryCount());
    sleep_s(10);
    console.log('There are',count,' total existing factories');
    if(count>0){
        for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer.getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
        sleep_s(20);
        let factory = await Factory.at(factory_address);
        sleep_s(20);
        let swaps = await factory.getCount();
        console.log('There are ',swaps,' in this factory');
        sleep_s(20);
        for(j = 0; j < swaps; j++){
            let swap_address = await factory.contracts.call(j);
            console.log('Swap Address',swap_address);
            let swap =await TokenToTokenSwap.at(swap_address);
            sleep_s(20);
            let variables = await swap.showPrivateVars();
            sleep_s(20);
            // [userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens,  duration,start_value, Start date, end_date, multiplier
            var endDate = variables[5];
            var x = 20;
            console.log('End Date: ', endDate);
            console.log('Date', _date);
            let state = await swap.currentState();
            sleep_s(20);
                if(endDate <= _date){     
                    let state = await swap.currentState();
                    sleep_s(20);
                    while(state == 1){
                        console.log('Paying Swap: ',swap_address);
                        console.log(await swap.showPrivateVars.call());
                        sleep_s(20);
                        await swap.forcePay(x);
                        sleep_s(20);
                        //x += 20;
                        state = await swap.currentState();
                        console.log("state", state);
                        sleep_s(20);
                    }
                } else {
                    console.log("not due");
                }
            }
        }
    }
}
