/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Tokendeployer = artifacts.require("Tokendeployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');

contract('Base Tests', function(accounts) {
  let oracle;
  let factory;
  let base1;
  let deployer;
  let userContract;
  let long_token;
  let short_token;
  let swap;
  let tokenDeployer;
  var swap_add;
  let o_startdate, o_enddate, balance1, balance2;

	beforeEach('Setup contract for each test', async function () {
		oracle = await Test_Oracle.new();
	    factory = await Factory.new();
	    await factory.setVariables(1000000000000000,7,1);
	    base = await Wrapped_Ether.new();
	    userContract = await UserContract.new();
	    deployer = await Deployer.new(factory.address);
	    tokenDeployer = await	Tokendeployer.new(factory.address);
	    await factory.setBaseToken(base.address);
	    await factory.setUserContract(userContract.address);
	    await factory.setDeployer(deployer.address);
	    await factory.setTokenDeployer(tokenDeployer.address);
	    await factory.setOracleAddress(oracle.address);
	    await userContract.setFactory(factory.address);
        o_startdate = 1514764800;
    	o_enddate = 1515369600;
    	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
  		balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
   		await factory.deployTokenContract(o_startdate,true);
    	await factory.deployTokenContract(o_startdate,false);
    	long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
   })
  	it("Up Move", async function(){
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal - 3 && balance1 <= newbal - 2 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 2 && balance2 <= newbal2 + 3 ,"Balance2 should change correctly");
		});
  	it("Down Move", async function(){
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,800);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal + 1 && balance1 <= newbal + 2 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 - 1 && balance2 <= newbal2 ,"Balance2 should change correctly");
		});

    it("Big Up Move", async function(){
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,2500);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal - 5 && balance1 <= newbal - 4 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 5 && balance2 <= newbal2 + 6 ,"Balance2 should change correctly");
		});
	it("Big Down Move", async function(){
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,0);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal - 5 && balance1 <= newbal +6 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 -5 && balance2 <= newbal2 -4,"Balance2 should change correctly");
	});
	it("Test Manual Up", async function(){
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1200);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await base.createToken({value: web3.toWei(20,'ether'), from: accounts[1]});
	  	await base.transfer(swap_add,20000000000000000000,{from: accounts[1]});
	  	await swap.CreateSwap(10000000000000000000,accounts[1],{from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal - 1 && balance1 <= newbal ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 1 && balance2 <= newbal2 + 2 ,"Balance2 should change correctly");
	});
	it("Test Manual Down", async function(){
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,600);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await base.createToken({value: web3.toWei(20,'ether'), from: accounts[1]});
	  	await base.transfer(swap_add,20000000000000000000,{from: accounts[1]});
	  	await swap.CreateSwap(10000000000000000000,accounts[1],{from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal + 1 && balance1 <= newbal + 2 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 - 3 && balance2 <= newbal2 - 2 ,"Balance2 should change correctly");
	});	
	it("Test Multiple Swaps", async function(){
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	    var swaps = [0]
	    var balances = []
	    var balances2 = []
	    for (i = 0; i <= 8; i++){
	    	balances[i] = eval(await (web3.fromWei(web3.eth.getBalance(accounts[i]), 'ether').toFixed(1)))
	    }
	    for (i=1;i<=4;i++){
		  	var receipt = await factory.deployContract(o_startdate,{from: accounts[i]});
		  	swap_add = receipt.logs[0].args._created;
		  	swaps[i] = await TokenToTokenSwap.at(swap_add);
		  	assert.equal(await swaps[i].current_state.call(),0,"Current State of swap " +i+" should be 0");
		  	await userContract.Initiate(swap_add,5000000000000000000,{value: web3.toWei(10,'ether'), from: accounts[i]});
		  	assert.equal(await swaps[i].current_state.call(),1,"Current State of swap " +i+" should be 1");
		  	await short_token.transfer(accounts[i+4],5000,{from:accounts[i]});
		  	await web3.eth.sendTransaction({from:accounts[i+4],to:accounts[i], value:web3.toWei(5, "ether")});
		}
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
		await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
		await short_token.transfer(accounts[2],5000,{from:accounts[5]});
		await web3.eth.sendTransaction({from:accounts[2],to:accounts[5], value:web3.toWei(5, "ether")});
		assert.equal(await long_token.balanceOf(accounts[1]),0,"first guy cashes out should send tokens");
		assert.equal(await short_token.balanceOf(accounts[1]),0,"first guy cashes out should send tokens");
		assert.equal(await short_token.balanceOf(accounts[2]),5000,"half of short tokens should be sent");
	  	for (i=1;i<=4;i++){
			await swaps[i].forcePay(1,100,{from:accounts[0]});
	  		assert.equal(await swaps[i].current_state.call(),2,"Current State of Swap "+i+" should be 2");
	  	}
	  	for (i = 0; i <= 8; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}

	    for (i = 0; i <= 8; i++){
	    	balances2[i] = eval(await (web3.fromWei(web3.eth.getBalance(accounts[i]), 'ether').toFixed(1)))
	    }
		assert(balances[1] <= balances2[1] + .5 && balances[1] >= balances2[1] ,"Balance1 should change correctly");
		assert(balances[2] <= balances2[2] + .5 && balances[2] >= balances2[2],"Balance2 should change correctly");
	});
	it("Test Over 100 Token Holders", async function(){

		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,800);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],4500,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(4.5, "ether")});
	  	await short_token.transfer(accounts[4],4500,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(4.5, "ether")});
	  	for(i =10; i < 100; i++){
	  		new_add ="0x0d7EFfEFdB084DfEB1621348c8C70cc4e871Eb" + i;
	  		new_add2 = "0x"+i+"0d7EFfEFdB084DfEB1621348c8C70cc4e871Eb";
	  		await long_token.transfer(new_add,50,{from:accounts[3]});
	  		await short_token.transfer(new_add2,50,{from:accounts[4]});
	  	}
	  	assert.equal(await long_token.balanceOf(accounts[1]),5500,"second balance should send tokens");
	  	assert.equal(await long_token.balanceOf(accounts[3]),0,"third balance should send tokens");
	  	assert.equal(await short_token.balanceOf("0x100d7EFfEFdB084DfEB1621348c8C70cc4e871Eb"),50,"One of the transfers should work");
	  	await swap.forcePay(1,20,{from:accounts[0]});
	  	await swap.forcePay(21,50,{from:accounts[0]});
	  	await swap.forcePay(51,80,{from:accounts[0]});
	  	await swap.forcePay(81,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal + 1 && balance1 <= newbal + 2 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 - 1 && balance2 <= newbal2 ,"Balance2 should change correctly");
	});

		it("Gas Calculation", async function(){

		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,800);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[4]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[4]});
	  	for(i =10; i < 100; i++){
	  		new_add ="0x0d7EFfEFdB084DfEB1621348c8C70cc4e871Eb" + i;
	  		new_add2 = "0x"+i+"0d7EFfEFdB084DfEB1621348c8C70cc4e871Eb";
	  		await long_token.transfer(new_add,50,{from:accounts[4]});
	  		await short_token.transfer(new_add2,50,{from:accounts[4]});
	  	}
	  	var gas_base = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(14)));
		await swap.forcePay(1,20,{from:accounts[0]});
		var gas_20 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(14)));
	  	await swap.forcePay(21,50,{from:accounts[0]});
	  	var gas_50 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(14)));
	  	await swap.forcePay(51,80,{from:accounts[0]});
	  	var gas_80 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(14)));
	  	console.log('First 20 cost',gas_base - gas_20);
	  	console.log('First 50 cost',gas_base - gas_50);
	  	console.log('First 80 cost', gas_base - gas_80);
	  	console.log('Average per holder', (gas_base-gas_80)/80);
	  	console.log('4,000,000 gas = ', 4000000/(gas_base-gas_80)/80, 'users')

	});
		it("Test Multiple Swaps - send all/ buy back", async function(){
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	    var swaps = [0]
	    var balances = []
	    var balances2 = []
	    for (i = 0; i <= 8; i++){
	    	balances[i] = eval(await (web3.fromWei(web3.eth.getBalance(accounts[i]), 'ether').toFixed(1)))
	    }
	    for (i=1;i<=4;i++){
		  	var receipt = await factory.deployContract(o_startdate,{from: accounts[i]});
		  	swap_add = receipt.logs[0].args._created;
		  	swaps[i] = await TokenToTokenSwap.at(swap_add);
		  	assert.equal(await swaps[i].current_state.call(),0,"Current State of swap " +i+" should be 0");
		  	await userContract.Initiate(swap_add,5000000000000000000,{value: web3.toWei(10,'ether'), from: accounts[i]});
		  	assert.equal(await swaps[i].current_state.call(),1,"Current State of swap " +i+" should be 1");
		  	await short_token.transfer(accounts[i+4],5000,{from:accounts[i]});
		  	await web3.eth.sendTransaction({from:accounts[i+4],to:accounts[i], value:web3.toWei(5, "ether")});
		}
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
		await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
		await long_token.transfer(accounts[1],5000,{from:accounts[4]});
		await web3.eth.sendTransaction({from:accounts[1],to:accounts[4], value:web3.toWei(5, "ether")});
		await short_token.transfer(accounts[2],5000,{from:accounts[5]});
		await web3.eth.sendTransaction({from:accounts[2],to:accounts[5], value:web3.toWei(5, "ether")});
		await long_token.transfer(accounts[2],5000,{from:accounts[3]});
		await web3.eth.sendTransaction({from:accounts[2],to:accounts[3], value:web3.toWei(5, "ether")});
		assert.equal(await long_token.balanceOf(accounts[1]),5000,"first guy cashes out should get it back");
		assert.equal(await short_token.balanceOf(accounts[1]),0,"first guy cashes out short tokens");
		assert.equal(await short_token.balanceOf(accounts[2]),5000,"half of short tokens should be sent");
		assert.equal(await long_token.balanceOf(accounts[2]),10000,"half of short tokens should be sent");
	  	for (i=1;i<=4;i++){
			await swaps[i].forcePay(1,100,{from:accounts[0]});
	  		assert.equal(await swaps[i].current_state.call(),2,"Current State of Swap "+i+" should be 2");
	  	}
	  	for (i = 0; i <= 8; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}

	    for (i = 0; i <= 8; i++){
	    	balances2[i] = eval(await (web3.fromWei(web3.eth.getBalance(accounts[i]), 'ether').toFixed(1)))
	    }
		assert(balances[1] <= balances2[1] - 2 && balances[1] >= balances2[1] -2.5 ,"Balance1 should change correctly");
		assert(balances[2] <= balances2[2] -2 && balances[2] >= balances2[2]-2.5,"Balance2 should change correctly");
	});
	it("Allowance Test", async function(){
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,800);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await short_token.approve(accounts[4],10000,{from:accounts[1]})
	  	await short_token.transferFrom(accounts[1],accounts[2],10000,{from:accounts[4]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.approve(accounts[4],5000,{from:accounts[1]})
	  	await long_token.transferFrom(accounts[1],accounts[3],5000,{from:accounts[4]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
	  	assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
		await swap.forcePay(1,100,{from:accounts[0]});
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		assert(balance1 >= newbal + 1 && balance1 <= newbal + 2 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 - 1 && balance2 <= newbal2 ,"Balance2 should change correctly");
		});
		it("Test Withdrawal and no trades", async function(){
			await factory.setFee(web3.toWei(1, 'ether'));
			await oracle.StoreDocument(o_startdate,1000);
		    await oracle.StoreDocument(o_enddate,1500);
		    var balance0 = eval(await (web3.fromWei(web3.eth.getBalance(accounts[0]), 'ether').toFixed(0)));
		  	var receipt = await factory.deployContract(o_startdate,{value: web3.toWei(1,'ether'),from: accounts[1]});
		  	swap_add = receipt.logs[0].args._created;
		  	swap = await TokenToTokenSwap.at(swap_add);
		  	assert.equal(await swap.current_state.call(),0,"Current State should be 0");
		  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
		  	assert.equal(await long_token.balanceOf(accounts[1]),10000,"second balance should send tokens");
			await swap.forcePay(1,100,{from:accounts[0]});
		  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
		  	for (i = 0; i < 5; i++){
			  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
			}
			await factory.withdrawFees();
			var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
			var newbal0 = eval(await web3.fromWei(web3.eth.getBalance(accounts[0]), 'ether').toFixed(0));
			assert(balance1 >= newbal + 1 && balance1 <= newbal + 2 ,"Balance1 should change correctly");
			assert(balance0 >= newbal0 - 2 && balance0 <= newbal0 - 1 ,"Balance0 should change correctly");
			});



});