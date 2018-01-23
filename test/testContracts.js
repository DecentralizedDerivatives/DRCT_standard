/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Wrapped_Ether2 = artifacts.require("Wrapped_Ether2");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Tokendeployer = artifacts.require("Tokendeployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');

contract('Contracts', function(accounts) {
  let oracle;
  let factory;
  let base1;
  let base2;
  let deployer;
  let userContract;
  let long_token;
  let short_token;
  let swap;
  let tokenDeployer;
  var swap_add;
  var account_one = accounts[0];
  var account_two = accounts[1];
  var account_three = accounts[2];
  var account_four = accounts[3];
  var account_five = accounts[4];


  it('Setup contract for testing', async function () {
  	oracle = await Test_Oracle.deployed();
  	console.log(oracle.address);
    factory = await Factory.deployed();
    await factory.setVariables(1000000000000000,1000000000000000,7,1);
    base1 = await Wrapped_Ether.deployed();
    base2 = await Wrapped_Ether2.deployed();
    userContract = await UserContract.deployed();
    deployer = await Deployer.deployed();
    tokenDeployer = await	Tokendeployer.deployed();
    await factory.setBaseTokens(base1.address,base2.address);
    await factory.setUserContract(userContract.address);
    await factory.setDeployer(deployer.address);
    await factory.settokenDeployer(tokenDeployer.address);
    await factory.setOracleAddress(oracle.address);
    await userContract.setFactory(factory.address);
  	assert.equal(await factory.user_contract.call(),userContract.address,"User Contract address not set correctly");
  });
  it("Up Move", async function(){
  	var o_startdate = 1552348800;
    var o_enddate = 1552953600;
  	var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
  	await oracle.StoreDocument(o_startdate,1000);
    await oracle.StoreDocument(o_enddate,1500);
    await factory.deployTokenContract(o_startdate,true);
    await factory.deployTokenContract(o_startdate,false);
    long_token_add =await factory.long_tokens(o_startdate);
    short_token_add =await factory.short_tokens(o_startdate);
    long_token =await DRCT_Token.at(long_token_add);
    short_token = await DRCT_Token.at(short_token_add);
    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
    assert.equal(await oracle.RetrieveData(o_enddate),1500,"Result should equal start value");
	console.log("Contracts deployed successfully")
  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
  	swap_add = receipt.logs[0].args._created;
  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
  	swap = await TokenToTokenSwap.at(swap_add);
  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_three});
  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
	console.log("Tokens Traded");
  	await long_token.transfer(account_four,5000,{from:account_two});
  	await short_token.transfer(account_five,5000,{from:account_three});
  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
  	assert.equal(await short_token.balanceOf(account_five),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
  	await swap.forcePay(1,100,{from:account_one});
  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
  	for (i = 0; i < 5; i++){
	  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
	  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
	}
	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
	var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	assert(balance1 >= newbal + 2.5 && balance1 <= newbal + 3.5 ,"Balance1 should change correctly");
	assert(balance2 >= newbal2 + 7 && balance2 <= newbal2 + 8 ,"Balance2 should change correctly");
	});
  it("Down Move", async function(){
  	var o_startdate = 1515628800;
    var o_enddate = 1516233600;
  	await oracle.StoreDocument(o_startdate,1000);
    await oracle.StoreDocument(o_enddate,500);
    await factory.deployTokenContract(o_startdate,true);
    await factory.deployTokenContract(o_startdate,false);
    long_token_add =await factory.long_tokens(o_startdate);
    short_token_add =await factory.short_tokens(o_startdate);
    long_token =await DRCT_Token.at(long_token_add);
    short_token = await DRCT_Token.at(short_token_add);
    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
    assert.equal(await oracle.RetrieveData(o_enddate),500,"Result should equal start value");
	console.log("Contracts deployed successfully")
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_three});
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");

	console.log("Tokens Traded");
	  	await long_token.transfer(account_five,5000,{from:account_two});
	  	await short_token.transfer(account_four,5000,{from:account_three});
	  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_four),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
	var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	assert(balance2 >= newbal2 + 2.6 && balance2 <= newbal2 + 3.6 ,"Balance2 should change correctly");
	assert(balance1 >= newbal + 7 && balance1 <= newbal + 8 ,"Balance1 should change correctly");
	});

    it("Big Up Move", async function(){
    var o_startdate = 1545091200;
    var o_enddate = 1545696000;
    await factory.deployTokenContract(o_startdate,true);
    await factory.deployTokenContract(o_startdate,false);
    long_token_add =await factory.long_tokens(o_startdate);
    short_token_add =await factory.short_tokens(o_startdate);
    long_token =await DRCT_Token.at(long_token_add);
    short_token = await DRCT_Token.at(short_token_add);
  	await oracle.StoreDocument(o_startdate,1000);
    await oracle.StoreDocument(o_enddate,7400);
    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_four), 'ether').toFixed(0));
  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_five), 'ether').toFixed(0));
    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
    assert.equal(await oracle.RetrieveData(o_enddate),7400,"Result should equal start value");
	console.log("Contracts deployed successfully");
	  	var receipt = await factory.deployContract(o_startdate,{from: account_four, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_four});
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_five});
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");

	console.log("Tokens Traded");
	  	await long_token.transfer(account_two,5000,{from:account_four});
	  	await short_token.transfer(account_three,5000,{from:account_five});
	  	assert.equal(await long_token.balanceOf(account_four),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_three),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_four), 'ether').toFixed(0)));
	var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_five), 'ether').toFixed(0));
	assert(balance2 >= newbal2  +10 && balance2 <= newbal2 + 11 ,"Balance2 should change correctly");
	assert(balance1 >= newbal && balance1 <= newbal + 1 ,"Balance1 should change correctly");
	});
	it("Big Down Move", async function(){
		var o_startdate = 1545696000;
	    var o_enddate = 1546300800;
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,0);
	    await factory.deployTokenContract(o_startdate,true);
	    await factory.deployTokenContract(o_startdate,false);
	    long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
	    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_four), 'ether').toFixed(0));
	  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_five), 'ether').toFixed(0));
	    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
	    assert.equal(await oracle.RetrieveData(o_enddate),0,"Result should equal start value");
		console.log("Contracts deployed successfully")
	  	var receipt = await factory.deployContract(o_startdate,{from: account_four, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_four});
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_five});
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");

	console.log("Tokens Traded");
	  	await long_token.transfer(account_two,5000,{from:account_four});
	  	await short_token.transfer(account_three,5000,{from:account_five});
	  	assert.equal(await long_token.balanceOf(account_four),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_three),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}

		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_four), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_five), 'ether').toFixed(0));
		assert(balance2 >= newbal2  && balance2 <= newbal2 + 1 ,"Balance2 should change correctly");
		assert(balance1 >= newbal + 10 && balance1 <= newbal + 11 ,"Balance1 should change correctly");
	});
	it("No Move", async function(){
		var o_startdate = 1546300800;
    	var o_enddate = 1546905600;
        await factory.deployTokenContract(o_startdate,true);
	    await factory.deployTokenContract(o_startdate,false);
	    long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1000);
	    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_four), 'ether').toFixed(0));
	  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_five), 'ether').toFixed(0));
	    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
	    assert.equal(await oracle.RetrieveData(o_enddate),1000,"Result should equal start value");
		console.log("Contracts deployed successfully")
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_three});
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");

	console.log("Tokens Traded");
	  	await long_token.transfer(account_four,5000,{from:account_two});
	  	await short_token.transfer(account_five,5000,{from:account_three});
	  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_five),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_four), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_five), 'ether').toFixed(0));
		assert(balance2 <= newbal2 - 4.5  && balance2 >= newbal2 - 5.5  ,"Balance2 should change correctly");
		assert(balance1 <= newbal - 4.5 && balance1 >= newbal - 5.5 ,"Balance1 should change correctly");
	});
	it("Test Manual Up", async function(){
			var o_startdate = 1546905600;
    var o_enddate = 1547510400;
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	    await factory.deployTokenContract(o_startdate,true);
    	await factory.deployTokenContract(o_startdate,false);
    	long_token_add =await factory.long_tokens(o_startdate);
    	short_token_add =await factory.short_tokens(o_startdate);
    	long_token =await DRCT_Token.at(long_token_add);
    	short_token = await DRCT_Token.at(short_token_add);
	    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  		var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
	    assert.equal(await oracle.RetrieveData(o_enddate),1500,"Result should equal start value");
		console.log("Contracts deployed successfully");
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await swap.CreateSwap(10000000000000000000,10000000000000000000,true,account_two,{from: account_two});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await base1.CreateToken({value: web3.toWei(10,'ether'), from: account_two});
	  	await base1.transfer(swap_add,10000000000000000000,{from: account_two});
	  	await swap.EnterSwap(10000000000000000000,10000000000000000000,false,account_three,{from: account_three});
	  	await base2.CreateToken({value: web3.toWei(10,'ether'), from: account_three});
	  	await base2.transfer(swap_add,10000000000000000000,{from: account_three});
	  	await swap.createTokens();
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
	  		console.log("Tokens Traded");
	  	await long_token.transfer(account_four,5000,{from:account_two});
	  	await short_token.transfer(account_five,5000,{from:account_three});
	  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_five),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
		assert(balance1 >= newbal + 2.5 && balance1 <= newbal + 3.5 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 7 && balance2 <= newbal2 + 8 ,"Balance2 should change correctly");
	});
	it("Test Manual Down", async function(){
		var o_startdate = 1547510400;
    	var o_enddate = 1548115200;
        await factory.deployTokenContract(o_startdate,true);
    	await factory.deployTokenContract(o_startdate,false);
    	long_token_add =await factory.long_tokens(o_startdate);
    	short_token_add =await factory.short_tokens(o_startdate);
    	long_token =await DRCT_Token.at(long_token_add);
    	short_token = await DRCT_Token.at(short_token_add);
		await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,500);
	    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  		var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
	    assert.equal(await oracle.RetrieveData(o_enddate),500,"Result should equal start value");
		console.log("Contracts deployed successfully");
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await swap.CreateSwap(10000000000000000000,10000000000000000000,true,account_two,{from: account_two});
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await base1.CreateToken({value: web3.toWei(10,'ether'), from: account_two});
	  	await base1.transfer(swap_add,10000000000000000000,{from: account_two});
	  	await swap.EnterSwap(10000000000000000000,10000000000000000000,false,account_three,{from: account_three});
	  	await base2.CreateToken({value: web3.toWei(10,'ether'), from: account_three});
	  	await base2.transfer(swap_add,10000000000000000000,{from: account_three});
	  	await swap.createTokens();
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
	  	console.log("Tokens Traded");
	  	await long_token.transfer(account_four,5000,{from:account_two});
	  	await short_token.transfer(account_five,5000,{from:account_three});
	  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_five),5000,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
		assert(balance2 >= newbal2 + 2.5 && balance2 <= newbal2 + 3.5 ,"Balance2 should change correctly");
		assert(balance1 >= newbal + 7 && balance1 <= newbal + 8 ,"Balance should change correctly");
	});
	
	it("Test Multiple Swaps", async function(){
		var o_startdate =1548115200;
    	var o_enddate = 1548720000;
        await factory.deployTokenContract(o_startdate,true);
    	await factory.deployTokenContract(o_startdate,false);
    	long_token_add =await factory.long_tokens(o_startdate);
    	short_token_add =await factory.short_tokens(o_startdate);
    	long_token =await DRCT_Token.at(long_token_add);
    	short_token = await DRCT_Token.at(short_token_add);
    	await oracle.StoreDocument(o_startdate,1000);
   		await oracle.StoreDocument(o_enddate,1500);
   		var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  		var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
    	assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
    	assert.equal(await oracle.RetrieveData(o_enddate),1500,"Result should equal start value");
		console.log("Contracts deployed successfully");
		  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
		  	swap_add1 = await receipt.logs[0].args._created;
		  	await userContract.Initiate(swap_add1,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
		  	swap1 = await TokenToTokenSwap.at(swap_add1);
		  	assert.equal(await swap1.current_state.call(),1,"Current State should be 1");
		  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add1,{value: web3.toWei(10,'ether'), from: account_three});
		  	assert.equal(await swap1.current_state.call(),3,"Current State should be 3");
		console.log('Entering Second and Third Swap')
		  		  	var receipt = await factory.deployContract(o_startdate,{from: account_four, gas:4000000});
		  	swap_add2 = receipt.logs[0].args._created;
		  	await userContract.Initiate(swap_add2,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_four});
		  	swap2 = TokenToTokenSwap.at(swap_add2);
		  	assert.equal(await swap2.current_state.call(),1,"Current State should be 1");
		  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add2,{value: web3.toWei(10,'ether'), from: account_five});
		  	assert.equal(await swap2.current_state.call(),3,"Current State should be 3");
		  		  	var receipt = await factory.deployContract(o_startdate,{from: account_five, gas:4000000});
		  	swap_add3 = receipt.logs[0].args._created;
		  	await userContract.Initiate(swap_add3,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_five});
		  	swap3 = TokenToTokenSwap.at(swap_add3);
		  	assert.equal(await swap3.current_state.call(),1,"Current State should be 1");
		  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add3,{value: web3.toWei(10,'ether'), from: account_four});
		  	assert.equal(await swap3.current_state.call(),3,"Current State should be 3");
		console.log("Tokens Traded");
		  	await long_token.transfer(account_four,5000,{from:account_two});
		  	await short_token.transfer(account_five,5000,{from:account_three});
		  	await long_token.transfer(account_four,5000,{from:account_five});
		  	await short_token.transfer(account_two,5000,{from:account_four});
		  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
		  	assert.equal(await short_token.balanceOf(account_two),5000,"second balance should get tokens");
		  	assert.equal(await short_token.balanceOf(account_five),15000,"half of short tokens should be sent");
		console.log("Contracts successfully closed");
		  	await swap1.forcePay(1,100,{from:account_one});
		  	await swap2.forcePay(1,100,{from:account_one});
		  	await swap3.forcePay(1,100,{from:account_one});
		  	assert.equal(await swap1.current_state.call(),5,"Current State should be 5");
		  	assert.equal(await swap2.current_state.call(),5,"Current State should be 5");
		  	assert.equal(await swap3.current_state.call(),5,"Current State should be 5");
		  	for (i = 0; i < 5; i++){
			  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
			  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
			}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
		assert(balance1 >= newbal - 1  && balance1 <= newbal ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 7 && balance2 <= newbal2 + 8 ,"Balance2 should change correctly");
	});
	it("Test Over 100 Token Holders", async function(){
		var o_startdate = 1548720000;
    	var o_enddate = 1549324800;
        await factory.deployTokenContract(o_startdate,true);
    	await factory.deployTokenContract(o_startdate,false);
   		long_token_add =await factory.long_tokens(o_startdate);
    	short_token_add =await factory.short_tokens(o_startdate);
   		long_token =await DRCT_Token.at(long_token_add);
    	short_token = await DRCT_Token.at(short_token_add);
		await oracle.StoreDocument(o_startdate,1000);
    	await oracle.StoreDocument(o_enddate,1500);
    	var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
    	console.log(balance1);
  		var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
    	assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
   		assert.equal(await oracle.RetrieveData(o_enddate),1500,"Result should equal start value");
		console.log("Contracts deployed successfully")
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_three});
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
		console.log("Tokens Traded to 100 people");
		var new_add = "";
	  	for(i =10; i < 100; i++){
	  		new_add ="0x0d7EFfEFdB084DfEB1621348c8C70cc4e871Eb" + i;
	  		new_add2 = "0x"+i+"0d7EFfEFdB084DfEB1621348c8C70cc4e871Eb";
	  		await long_token.transfer(new_add,50,{from:account_two});
	  		await short_token.transfer(new_add2,50,{from:account_three});
	  	}
	  	console.log(await long_token.balanceOf(account_two));
	  	assert.equal(await long_token.balanceOf(account_two),5500,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf("0x100d7EFfEFdB084DfEB1621348c8C70cc4e871Eb"),50,"One of the transfers should work");
		console.log("Contracts successfully closed");
	  	await swap.forcePay(1,20,{from:account_one});
	  	await swap.forcePay(21,50,{from:account_one});
	  	await swap.forcePay(51,80,{from:account_one});
	  	await swap.forcePay(81,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	var newbalx = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		console.log(newbalx);
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		console.log(newbal);
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
		assert(balance1 >= newbal + 3.5 && balance1 <= newbal + 4.5 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 8.2 && balance2 <= newbal2 + 9.2 ,"Balance2 should change correctly");
	});
		it("Test Exit - Stage 1", async function(){
		var o_startdate = 1549324800;
		var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await swap.Exit({from: account_two});
	  	await base1.withdraw(await base1.balanceOf(accounts[1]),{from:accounts[1]});
	  	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		assert(balance1 <= newbal + 1 && balance1 >= newbal,"Balance1 should change correctly");
	});

	it("Test Exit - Stage 2", async function(){
		var o_startdate = 1549929600;
		var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
		var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await swap.EnterSwap(10000000000000000000,10000000000000000000,false,account_three,{from: account_three});
	  	await swap.Exit({from: account_three});
	  	await base1.withdraw(await base1.balanceOf(accounts[1]),{from:accounts[1]});
	  	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
		assert(balance1 <= newbal + 1 && balance1 >= newbal,"Balance1 should change correctly");

	});
	it("Test Exit - Stage 3", async function(){
		var o_startdate = 1550534400;
		var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await factory.deployTokenContract(o_startdate,true);
    	await factory.deployTokenContract(o_startdate,false);
	    long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
	  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_three});
	  	await swap.Exit({from: account_three});
	  	assert(await base1.balanceOf(accounts[1]),0,"You should not be able to exit");
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
	});
	it("Test Withdrawal", async function(){
		console.log('Sending Ether and Tokens');
		await base1.CreateToken({value: web3.toWei(1,'ether'), from: account_two});
		await base1.transfer(factory.address,web3.toWei(1,'ether'),{from: account_two});
		await base2.CreateToken({value: web3.toWei(1,'ether'), from: account_three});
		await base2.transfer(factory.address,web3.toWei(1,'ether'),{from: account_three});
		await factory.deployContract(1,{from: account_two, to: factory.address, value: web3.toWei(1, 'ether') })
		//withdraw from factory
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_one), 'ether').toFixed(0)));
		await factory.withdrawFees();
		var newbal2 = eval(await (web3.fromWei(web3.eth.getBalance(account_one), 'ether').toFixed(0)));
	  	console.log(newbal,newbal2);
	  	assert(newbal >= newbal2 - 4 && newbal <= newbal2 -3,"Value should changed correctly");
	});

	it("Up Move w/ Premium", async function(){
  	var o_startdate = 1550880000;
    var o_enddate = 1550966400;
  	var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
  	await oracle.StoreDocument(o_startdate,1000);
    await oracle.StoreDocument(o_enddate,1500);
    await factory.deployTokenContract(o_startdate,true);
    await factory.deployTokenContract(o_startdate,false);
    long_token_add =await factory.long_tokens(o_startdate);
    short_token_add =await factory.short_tokens(o_startdate);
    long_token =await DRCT_Token.at(long_token_add);
    short_token = await DRCT_Token.at(short_token_add);
    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal start value");
    assert.equal(await oracle.RetrieveData(o_enddate),1500,"Result should equal end value");
	console.log("Contracts deployed successfully")
  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
  	swap_add = receipt.logs[0].args._created;
  	await userContract.Initiate(swap_add,1000000000000000000,1000000000000000000,web3.toWei(1, 'ether'),true,{value: web3.toWei(2,'ether'), from: account_two});
  	swap = await TokenToTokenSwap.at(swap_add);
  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
  	await userContract.Enter(1000000000000000000,1000000000000000000,false,swap_add,{value: web3.toWei(1,'ether'), from: account_three});
  	var prem_balance = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
  	console.log(prem_balance, balance2);
  	assert(prem_balance + .1 >= balance2, "Premium should be paid");
  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
	console.log("Tokens Traded");
  	await long_token.transfer(account_four,500,{from:account_two});
  	await short_token.transfer(account_five,500,{from:account_three});
  	assert.equal(await long_token.balanceOf(account_two),500,"second balance should send tokens");
  	assert.equal(await short_token.balanceOf(account_five),500,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
  	await swap.forcePay(1,100,{from:account_one});
  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
  	for (i = 0; i < 5; i++){
	  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
	  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
	}
	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
	var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	console.log(balance1, balance2, newbal, newbal2);
	assert(balance1 >= newbal + 1.5 && balance1 <= newbal +  3 ,"Balance1 should change correctly");
	assert(balance2 >= newbal2 - 1 && balance2 <= newbal2 ,"Balance2 should change correctly");
	});
  it("Down Move w/ Premium", async function(){
  	var o_startdate = 1550966400;
    var o_enddate = 1551052800;
  	await oracle.StoreDocument(o_startdate,1000);
    await oracle.StoreDocument(o_enddate,500);
    await factory.deployTokenContract(o_startdate,true);
    await factory.deployTokenContract(o_startdate,false);
    long_token_add =await factory.long_tokens(o_startdate);
    short_token_add =await factory.short_tokens(o_startdate);
    long_token =await DRCT_Token.at(long_token_add);
    short_token = await DRCT_Token.at(short_token_add);
    var balance1 = await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0));
  	var balance2 = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
    assert.equal(await oracle.RetrieveData(o_startdate),1000,"Result should equal end value");
    assert.equal(await oracle.RetrieveData(o_enddate),500,"Result should equal start value");
	console.log("Contracts deployed successfully")
	  	var receipt = await factory.deployContract(o_startdate,{from: account_two, gas:4000000});
	  	swap_add = receipt.logs[0].args._created;
	  	await userContract.Initiate(swap_add,1000000000000000000,1000000000000000000,web3.toWei(1,'ether'),true,{value: web3.toWei(2,'ether'), from: account_two});
	  	swap = TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
	  	await userContract.Enter(1000000000000000000,1000000000000000000,false,swap_add,{value: web3.toWei(1,'ether'), from: account_three});
	  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
	  	var prem_balance = await (web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	  	  	console.log(prem_balance, balance2);
  		assert(prem_balance + .1 >= balance2, "Premium should be paid");
	console.log("Tokens Traded");
	  	await long_token.transfer(account_five,500,{from:account_two});
	  	await short_token.transfer(account_four,500,{from:account_three});
	  	assert.equal(await long_token.balanceOf(account_two),500,"second balance should send tokens");
	  	assert.equal(await short_token.balanceOf(account_four),500,"half of short tokens should be sent");
	console.log("Contracts successfully closed");
	  	await swap.forcePay(1,100,{from:account_one});
	  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
	  	for (i = 0; i < 5; i++){
		  	await base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
		  	await base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
		}
	var newbal = eval(await (web3.fromWei(web3.eth.getBalance(account_two), 'ether').toFixed(0)));
	var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(account_three), 'ether').toFixed(0));
	console.log(balance1, balance2, newbal, newbal2);
	assert(balance2 >= newbal2 - 1 && balance2 <= newbal2 ,"Balance2 should change correctly");
	assert(balance1 >= newbal + 1.75 && balance1 <= newbal + 2.25 ,"Balance1 should change correctly");
	});

});

