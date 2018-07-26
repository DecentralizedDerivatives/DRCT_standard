/**
*Check which contracts expired and force pay them.
*/
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
var _master = "0xb9910c2269cb3953e4b4332ef6f782af97a4699f"; 

module.exports =async function(callback) {

    let masterDeployer = await MasterDeployer.at(_master);
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
    if(count>0){
        for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
        let factory = await Factory.at(factory_address);
        let swaps = await factory.getCount();
        console.log('There are ',swaps,' in this factory');
        for(j = 0; j < swaps; j++){
            let swap_address = await factory.contracts.call(j);
            console.log('Swap Address',swap_address);
            let swap =await TokenToTokenSwap.at(swap_address);
            let variables = await swap.showPrivateVars();
            // [userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens,  duration,start_value, Start date, end_date, multiplier
            var endDate = variables[5];
            var x = 20;
            console.log('End Date: ', endDate);
            console.log('Date', _date);
            let state = await swap.currentState();
                if(endDate <= _date){     
                    let state = await swap.currentState();
                    while(state == 1){
                        console.log('Paying Swap: ',swap_address);
                        console.log(await swap.showPrivateVars.call());
                        await swap.forcePay(x);
                        //x += 20;
                        state = await swap.currentState();
                        console.log("state", state);
                    }
                }
            }
        }
    }
}
