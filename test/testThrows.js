/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Membership = artifacts.require("Membership");
var Exchange = artifacts.require("Exchange");
var MasterDeployer = artifacts.require("MasterDeployer");


async function expectThrow(promise){
  try {
    await promise;
  } catch (error) {
    // TODO: Check jump destination to destinguish between a throw
    //       and an actual invalid jump.
    const invalidOpcode = error.message.search('invalid opcode') >= 0;
    // TODO: When we contract A calls contract B, and B throws, instead
    //       of an 'invalid jump', we get an 'out of gas' error. How do
    //       we distinguish this from an actual out of gas event? (The
    //       testrpc log actually show an 'invalid jump' event.)
    const outOfGas = error.message.search('out of gas') >= 0;
    const revert = error.message.search('revert') >= 0;
    assert(
      invalidOpcode || outOfGas || revert,
      'Expected throw, got \'' + error + '\' instead',
    );
    return;
  }
  assert.fail('Expected throw not received');
};


contract('Throw Tests', function(accounts) {
  let oracle;
  let factory;
  let base1;
  let deployer;
  let memberCoin;
  let userContract;
  let long_token;
  let short_token;
  let swap;
  let exchange;
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
    it("Throw testing upmove", async function() {
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	  	await expectThrow(userContract.Initiate(o_startdate,10000000000000000000,{value: web3.toWei(10,'ether'), from: accounts[2]}));
	  	var receipt = await userContract.Initiate(o_startdate,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
		await swap.forcePay(50,{from:accounts[0]});
		await expectThrow(swap.forcePay(50,{from:accounts[0]}));
	  	assert.equal(await swap.currentState(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		await expectThrow(base.withdraw(await 10000000000000000,{from:accounts[1]}));
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		});

	 it("Return false on uncalled oraclize", async function() {
	  	await oracle.StoreDocument(o_startdate,1000);
		var receipt = await userContract.Initiate(o_startdate,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
		await swap.forcePay(50,{from:accounts[0]});
		assert.equal(await swap.currentState(),1,"Current State should be 1");
		await oracle.StoreDocument(o_enddate,1500);
		await swap.forcePay(50,{from:accounts[0]});
	  	assert.equal(await swap.currentState(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		});
		it("Throw on unwhitelisted - Create", async function() {

	    factory = await Factory.new(1001);

	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(1001);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    //await factory.setWhitelistedMemberTypes([0]);
	    await factory.setVariables(1000000000000000,7,1,0);

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

			//await factory.setWhitelistedMemberTypes([1,2,3]);
			await memberCoin.setMembershipType(accounts[1],1000)
	  		await expectThrow(factory.deployContract(o_startdate,accounts[1],{from: accounts[1]}));
		});

		it("Throw on unwhitelisted - Transfer", async function() {
			//await factory.setWhitelistedMemberTypes([1,100,200]);

	    factory = await Factory.new(1);

	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(1);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    //await factory.setWhitelistedMemberTypes([0]);
	    await factory.setVariables(1000000000000000,7,1,0);

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
			await oracle.StoreDocument(o_startdate,1000);
		    await oracle.StoreDocument(o_enddate,1500);
		var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
		  	await expectThrow(short_token.transfer(accounts[2],10000,{from:accounts[1]}));
		});
		it("Throw on unwhitelisted - Sell", async function() {
	    factory = await Factory.new(999);

	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(999);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    //await factory.setWhitelistedMemberTypes([0]);
	    await factory.setVariables(1000000000000000,7,1,0);

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

			//await factory.setWhitelistedMemberTypes([1000]);
			await memberCoin.setMembershipType(accounts[1],1000);
		var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
			await short_token.approve(exchange.address,500,{from: accounts[1]});
			balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
			await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[1]});
			await expectThrow(exchange.buy(1,{from: accounts[2], value:web3.toWei(5,'ether')}));
		});
				it("Throw on unwhitelisted create for third party- Sell", async function() {
	    factory = await Factory.new(999);

	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(999);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    //await factory.setWhitelistedMemberTypes([0]);
	    await factory.setVariables(1000000000000000,7,1,0);

	    deployer = await Deployer.new(factory.address);
	    await factory.setBaseToken(base.address);
	    await factory.setUserContract(userContract.address);
	    await factory.setDeployer(deployer.address);
	    await factory.setOracleAddress(oracle.address);
	    await userContract.setFactory(factory.address);
        o_startdate = 1514764800;
   		await factory.deployTokenContract(o_startdate);
			//await factory.setWhitelistedMemberTypes([1000]);
			await memberCoin.setMembershipType(accounts[1],1000);
			var receipt = await factory.deployContract(o_startdate,accounts[1],{from: accounts[2]});
		  	swap_add = receipt.logs[0].args._created;
		  	swap = await TokenToTokenSwap.at(swap_add);
		  	await base.createToken({value: web3.toWei(2,'ether'), from: accounts[2]});
		  	await base.createToken({value: web3.toWei(2,'ether'), from: accounts[2]});
		  	await base.transfer(swap_add,2000000000000000000,{from: accounts[2]});
		  	await expectThrow(swap.createSwap(1000000000000000000,accounts[2],{from: accounts[2]}));
		});
		it("no throw on WhiteListedMemberTypes[0] - Create", async function() {

	    factory = await Factory.new(0);

	    await masterDeployer.setFactory(factory.address);
	    let res = await masterDeployer.deployFactory(0);
	    res = res.logs[0].args._factory;
	    factory = await Factory.at(res);
	    await factory.setMemberContract(memberCoin.address);
	    
	    await factory.setVariables(1000000000000000,7,1,0);

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

			
			await memberCoin.setMembershipType(accounts[1],0)
			await factory.deployContract(o_startdate,accounts[1],{from: accounts[1]});
	  		//await expectThrow(factory.deployContract(o_startdate,{from: accounts[1]}));
		});
			it("Test Multiple List", async function(){
	  	var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.approve(exchange.address,500,{from: accounts[1]});;
	  	assert.equal(await short_token.allowance(accounts[1],exchange.address),500,"exchange should own tokens");
	  	await exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[1]});
	  	await expectThrow(exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[1]}));

	})
});
