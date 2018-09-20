/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
/*var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Exchange = artifacts.require("Exchange");
var Membership = artifacts.require("Membership");
var MasterDeployer = artifacts.require("MasterDeployer");

contract('Exchange Test', function(accounts) {
  let oracle;
  let exchange;
  let memberCoin;
  let factory;
  let base1;
  let deployer;
  let userContract;
  let long_token;
  let short_token;
  let swap;
  var swap_add;
  let masterDeployer;
  let o_startdate, o_enddate, balance1, balance2;

	beforeEach('Setup contract for each test', async function () {
		oracle = await Test_Oracle.new("https://api.gdax.com/products/BTC-USD/ticker).price");
	    factory = await Factory.new(0);
	    memberCoin = await Membership.new();
	    masterDeployer = await MasterDeployer.new();
	     exchange = await Exchange.new();
	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(0);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    //await factory.setWhitelistedMemberTypes([0]);
	    await factory.setVariables(1000000000000000,7,1,0);
	    base = await Wrapped_Ether.new();
	    userContract = await UserContract.new();
	    deployer = await Deployer.new(factory.address);
	    await factory.setBaseToken(base.address);
	    await factory.setUserContract(userContract.address);
	    await factory.setDeployer(deployer.address);
	    await factory.setOracleAddress(oracle.address);
	    await userContract.setFactory(factory.address);
        o_startdate = 1514764800;
    	o_enddate = 1515369600;
    	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1));
  		balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
   		await factory.deployTokenContract(o_startdate);
    	long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
   })
	it("Test List", async function(){
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});;
	  	assert.equal(await short_token.allowance(accounts[1],exchange.address),500,"exchange should own tokens");
	  	await exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[1]});
	  	details = await exchange.getOrder(1);
	  	assert.equal(details[0],accounts[1], "Address 1 should be maker");
	  	assert.equal(details[1], web3.toWei(10,'ether'),"Price should be 10 Ether");
	  	assert.equal(details[2], 500, "Amount listed should be 500");
	  	assert.equal(details[3], short_token.address, "Short token address should be order");
	  	assert.equal(await exchange.getOrderCount(short_token.address),2, "Short Token should have an order");
	})
	it("Test Buy", async function(){

		var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[1]});
	  	await exchange.buy(1,{from: accounts[2], value:web3.toWei(5,'ether')})
	  	assert.equal(await short_token.balanceOf(accounts[2]),500,"account 2 should own tokens");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	assert.equal(balance1, balance1_2 - 5,"account 1 should get 2 ether");
	});
	it("Test Unlist", async function(){
		var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});;
	  	await exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[1]});
	  	await exchange.unlist(1,{from: accounts[1]});
	  	assert.equal(await short_token.balanceOf(accounts[1]),1000,"account 1 should have all tokens");
	  	assert.equal(await exchange.getOrderCount(short_token.address) - 0,0, "Short Token should have no orders");
	});

	it("Test ddaList", async function(){
		await exchange.listDda(long_token_add, 100, 1, true,{from: accounts[0]});
		await exchange.listDda(short_token_add, 100, 1, false, {from: accounts[0]});
		resl = await exchange.getDdaListAssetInfo(long_token_add);
		res = await exchange.getDdaListAssetInfo(short_token_add);
		assert( resl = [1,100,true], "Long info");
		assert( res = [1,100,false], "short info");
	});

	it("Test dda Unlist", async function(){
		await exchange.listDda(long_token_add, 100, 1, true,{from: accounts[0]});
		await exchange.listDda(short_token_add, 100, 1, false, {from: accounts[0]});
		resl = await exchange.getDdaListAssetInfo(long_token_add);
		res = await exchange.getDdaListAssetInfo(short_token_add);
		assert( resl = [1,100,true], "Long info");
		assert( res = [1,100,false], "short info");
		await exchange.unlistDda(long_token_add,{from: accounts[0]});
		await exchange.unlistDda(short_token_add, {from: accounts[0]});
		res3 = await exchange.getDdaListAssetInfo(long_token_add);
		res4 = await exchange.getDdaListAssetInfo(short_token_add);
	    assert( res3 = [0,0,false], "Long info");
		assert( res4 = [0,0,false], "short info");
	});
	it("Test dda buy", async function(){
		var receipt = await factory.deployContract(o_startdate,{from: accounts[0]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[0]});
		await exchange.listDda(long_token_add, 100, web3.toWei(1,'ether'), true,{from: accounts[0]});
		await exchange.listDda(short_token_add, 100, web3.toWei(1,'ether'), false, {from: accounts[0]});
		await short_token.approve(exchange.address,200,{from: accounts[0]});
		await long_token.approve(exchange.address,200,{from: accounts[0]});
		await exchange.buyPerUnit(long_token_add, 1, {from: accounts[8], value:web3.toWei(1,'ether')});
		await exchange.buyPerUnit(short_token_add, 2,{from: accounts[8], value:web3.toWei(2,'ether')});
		resl = await exchange.getDdaListAssetInfo(long_token_add);
		res = await exchange.getDdaListAssetInfo(short_token_add);
		console.log(resl, res);
		assert( resl = [1,99,true], "Long info");
		assert( res = [1,98,false], "short info");
	})

	
	it("Test 100 Lists and Sales", async function(){
		var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
		await short_token.approve(exchange.address,500,{from: accounts[1]});
	  	for(i=0;i<100;i++){
		  	await exchange.list(short_token.address,5,web3.toWei(.05,'ether'),{from: accounts[1]});
	  	}
	  	assert.equal(await exchange.getOrderCount(short_token.address)-0,101, "There should be 100 orders");
	  	assert.equal(await short_token.allowance(accounts[1],exchange.address)-0,500,"exchange should own tokens");
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	for(i=0;i<100;i++){
			await exchange.buy(i+1,{from: accounts[3], value:web3.toWei(.05,'ether')})
	  	}
	  	assert.equal(await exchange.getOrderCount(short_token.address)-0,0, "Short Token should have no orders");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	assert.equal(balance1, balance1_2 - 5,"account 1 should get 5 ether");
	});
	it("Test Buy then Sell then Buy then List then Unlist", async function(){
		var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[1]});
	  	await exchange.buy(1,{from: accounts[2], value:web3.toWei(5,'ether')})
	  	assert.equal(await short_token.balanceOf(accounts[2]),500,"account 2 should own tokens");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	assert(balance1 >= balance1_2 - 5 && balance1 <= balance1_2 - 4 ,"account 1 should get 5 ether");
	  	await short_token.approve(exchange.address,500,{from: accounts[2]});;
	  	await exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[2]});
	  	assert.equal(await short_token.balanceOf(accounts[2])-0,500,"account 2 should still own tokens");
	  	await exchange.unlist(2,{from: accounts[2]});
	  	assert.equal(await exchange.getOrderCount(short_token.address) - 0,0, "Short Token should have no orders");
	  	await short_token.approve(exchange.address,500,{from: accounts[2]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[2]});
	  	await exchange.buy(3,{from: accounts[1], value:web3.toWei(5,'ether')})
	  	assert.equal(await short_token.balanceOf(accounts[1]),1000,"account 1 should own all tokens");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
	  	assert.equal(balance1, balance1_2 - 5,"account 2 should get 5 ether");

	});

	it("Test Whitelist", async function(){
		oracle = await Test_Oracle.new("https://api.gdax.com/products/BTC-USD/ticker).price");
	    factory = await Factory.new(1);
	    memberCoin = await Membership.new();
	    masterDeployer = await MasterDeployer.new();
	     exchange = await Exchange.new();
	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(1);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    //await factory.setWhitelistedMemberTypes([0]);
	    await factory.setVariables(1000000000000000,7,1,0);
	    base = await Wrapped_Ether.new();
	    userContract = await UserContract.new();
	    deployer = await Deployer.new(factory.address);
	    await factory.setBaseToken(base.address);
	    await factory.setUserContract(userContract.address);
	    await factory.setDeployer(deployer.address);
	    await factory.setOracleAddress(oracle.address);
	    await userContract.setFactory(factory.address);
        o_startdate = 1514764800;
    	o_enddate = 1515369600;
    	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1));
  		balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
   		await factory.deployTokenContract(o_startdate);
    	long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);

		//await factory.setWhitelistedMemberTypes([1,100,200]);
		await memberCoin.setMembershipType(accounts[1],1);
		await memberCoin.setMembershipType(accounts[2],100);
		await memberCoin.setMembershipType(accounts[3],200);
		var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[1]});
	  	await exchange.buy(1,{from: accounts[2], value:web3.toWei(5,'ether')})
	  	assert.equal(await short_token.balanceOf(accounts[2]),500,"account 2 should own tokens");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	assert.equal(balance1, balance1_2 - 5,"account 1 should get 5 ether");
	  	await short_token.approve(exchange.address,500,{from: accounts[2]});;
	  	await exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[2]});
	  	assert.equal(await short_token.balanceOf(accounts[2])-0,500,"account 2 should still own tokens");
	  	await exchange.unlist(2,{from: accounts[2]});
	  	assert.equal(await exchange.getOrderCount(short_token.address) - 0,0, "Short Token should have no orders");
	  	await short_token.approve(exchange.address,500,{from: accounts[2]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[2]});
	  	await exchange.buy(3,{from: accounts[1], value:web3.toWei(5,'ether')})
	  	assert.equal(await short_token.balanceOf(accounts[1]),1000,"account 1 should own all tokens");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
	  	assert.equal(balance1, balance1_2 - 5,"account 2 should get 5 ether");
	  	await short_token.transfer(accounts[3],500,{from:accounts[1]});
	});
		it("Test Whitelist 2", async function(){
		oracle = await Test_Oracle.new("https://api.gdax.com/products/BTC-USD/ticker).price");
	    factory = await Factory.new(0);
	    memberCoin = await Membership.new();
	    masterDeployer = await MasterDeployer.new();
	     exchange = await Exchange.new();
	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(0);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    await factory.setVariables(1000000000000000,7,1,0);
	    base = await Wrapped_Ether.new();
	    userContract = await UserContract.new();
	    deployer = await Deployer.new(factory.address);
	    await factory.setBaseToken(base.address);
	    await factory.setUserContract(userContract.address);
	    await factory.setDeployer(deployer.address);
	    await factory.setOracleAddress(oracle.address);
	    await userContract.setFactory(factory.address);
        o_startdate = 1514764800;
    	o_enddate = 1515369600;
    	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1));
  		balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
   		await factory.deployTokenContract(o_startdate);
    	long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
		await memberCoin.setMembershipType(accounts[1],1);
		var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await userContract.Initiate(swap_add,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[1]});
	  	await exchange.buy(1,{from: accounts[2], value:web3.toWei(5,'ether')})
	  	assert.equal(await short_token.balanceOf(accounts[2]),500,"account 2 should own tokens");
	});
});

*/