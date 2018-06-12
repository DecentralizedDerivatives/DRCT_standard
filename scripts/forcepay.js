var Oracle = artifacts.require("Oracle");
var MasterDeployer = artifacts.require("MasterDeployer");
var Factory = artifacts.require("Factory");
var TokenToTokenSwap = artifacts.require("TokenToTokenSwap");
var _date = Date.now()/1000- (Date.now()/1000)%86400;


module.exports =async function(callback) {
 
    let masterDeployer = await MasterDeployer.deployed();
    var count = parseInt(await masterDeployer.getFactoryCount());
    console.log('There are',count,' total existing factories');
 
    for(i = 1; i <= count; i++){
        var factory_address = await masterDeployer. getFactorybyIndex(i);
        console.log('Factory Address',factory_address);
        let factory = await Factory.at(factory_address);
        let swaps = await factory.getCount();
        for(j = 0; j < count; j++){
        	let swap_address = await factory.contracts.call(j);
        	console.log('Swap Address',swap_address);
        	let swap =await TokenToTokenSwap.at(swap_address);
        	let variables = await swap.showPrivateVars();
        	    // [userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens,  duration,start_value, Start date, end_date, multiplier
        	console.log('Variables: ',variables);
        	var endDate = variables[5];
        	var x = 0;
        	var y = 50;
        	var finished = false;
        	console.log('End Date: ', endDate);
        	console.log('Date', _date);
        	if(endDate <= _date){       		 
        		 if(!finished){
        		 	finished = await swap.forcePay(x,y);
        		 	console.log('Finished: ',finished);
        		 	x += 50;
        		 	y += 50;
        		 }

        	}
        }
  	}
}
