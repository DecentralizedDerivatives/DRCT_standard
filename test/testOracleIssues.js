// /*this contract tests the typical workflow from the dApp (user contract, cash out)*/
// var Test_Oracle = artifacts.require("Test_Oracle");
// var Wrapped_Ether = artifacts.require("Wrapped_Ether");
// var Factory = artifacts.require("Factory");
// var UserContract= artifacts.require("UserContract");
// var Deployer = artifacts.require("Deployer");
// var Tokendeployer = artifacts.require("Tokendeployer");
// const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
// const DRCT_Token = artifacts.require('./DRCT_Token.sol');

// contract('Contracts', function(accounts) {
//   let oracle;
//   let factory;
//   let base1;
//   let deployer;
//   let userContract;
//   let long_token;
//   let short_token;
//   let swap;
//   let tokenDeployer;
//   var swap_add;
//   let o_startdate, o_enddate, balance1, balance2;

// 	beforeEach('Setup contract for each test', async function () {
// 		oracle = await Test_Oracle.new();
// 	    factory = await Factory.new();
// 	    await factory.setVariables(1000000000000000,7,1);
// 	    base = await Wrapped_Ether.new();
// 	    userContract = await UserContract.new();
// 	    deployer = await Deployer.new(factory.address);
// 	    tokenDeployer = await	Tokendeployer.new(factory.address);
// 	    await factory.setBaseToken(base.address);
// 	    await factory.setUserContract(userContract.address);
// 	    await factory.setDeployer(deployer.address);
// 	    await factory.setTokenDeployer(tokenDeployer.address);
// 	    await factory.setOracleAddress(oracle.address);
// 	    await userContract.setFactory(factory.address);
//         o_startdate = 1514764800;
//     	o_enddate = 1515369600;
//     	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1));
//   		balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
//    		await factory.deployTokenContract(o_startdate,true);
//     	await factory.deployTokenContract(o_startdate,false);
//     	long_token_add =await factory.long_tokens(o_startdate);
// 	    short_token_add =await factory.short_tokens(o_startdate);
// 	    long_token =await DRCT_Token.at(long_token_add);
// 	    short_token = await DRCT_Token.at(short_token_add);
//    })
// 	it("Test Oracle", async function(){
// 	  	await oracle.StoreDocument(o_startdate,1000);
// 	    await oracle.StoreDocument(o_enddate,1500);
// 	    assert.equal(await factory.user_contract.call(),userContract.address,"User Contract address not set correctly");
// 	    assert.equal(await oracle.retrieveData(o_startdate),1000,"Result should equal end value");
// 	    assert.equal(await oracle.retrieveData(o_enddate),1500,"Result should equal start value");
// 		})
  	
// 	it("Missed Dates", async function(){
// 		await oracle.StoreDocument(o_startdate + 86400,1000);
// 	    await oracle.StoreDocument(o_enddate + 86400,1500);
// 	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
// 	  	swap_add = receipt.logs[0].args._created;
// 	  	swap = await TokenToTokenSwap.at(swap_add);
// 	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
// 	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
// 	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
// 	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
// 	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
// 		await swap.forcePay(1,100,{from:accounts[0]});
// 	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
// 	  	for (i = 0; i < 5; i++){
// 		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
// 		}
// 		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1)));
// 		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
// 		assert(balance1 >= newbal - 5.5 && balance1 <= newbal - 4.5 ,"Balance1 should change correctly");
// 		assert(balance2 >= newbal2 + 5 && balance2 <= newbal2 + 6 ,"Balance2 should change correctly");
// 	});
// });

