/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle2 = artifacts.require("Test_Oracle2");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Exchange = artifacts.require("Exchange");
var ExchangeStorage = artifacts.require("ExchangeStorage");
var Membership = artifacts.require("Membership");
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

contract('Exchange Storage Test', function(accounts) {
  let oracle;
  let exchange;
  let exchange2;
  let exchangeStorage;
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
        oracle = await Test_Oracle2.new("json(https://api.gdax.com/products/BTC-USD/ticker).price", "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price");	    factory = await Factory.new(0);
	    memberCoin = await Membership.new();
	    masterDeployer = await MasterDeployer.new();
	    exchange = await Exchange.new();
	    exchange2 = await Exchange.new();
	    exchangeStorage = await ExchangeStorage.new();
	    await exchangeStorage.setDexAddress(exchange.address);
	    await exchange.setDexStorageAddress(exchangeStorage.address);
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
	  	var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.approve(exchangeStorage.address,500,{from: accounts[1]});;
	  	assert.equal(await short_token.allowance(accounts[1],exchangeStorage.address),500,"exchange should own tokens");
	  	await exchange.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[1]});
	  	details = await exchangeStorage.getOrder(1);
	  	assert.equal(details[0],accounts[1], "Address 1 should be maker");
	  	assert.equal(details[1], web3.toWei(10,'ether'),"Price should be 10 Ether");
	  	assert.equal(details[2], 500, "Amount listed should be 500");
	  	assert.equal(details[3], short_token.address, "Short token address should be order");
	  	console.log("order count", await exchangeStorage.getOrderCount(short_token.address));
	  	assert.equal(await exchangeStorage.getOrderCount(short_token.address),2, "Short Token should have an order");
	})
	it("Test List from two exchanges", async function(){
	  	var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.approve(exchangeStorage.address,500,{from: accounts[1]});
	  	assert.equal(await short_token.allowance(accounts[1],exchangeStorage.address),500,"exchange should own tokens");
	  	await exchange.list(short_token.address,300,web3.toWei(10,'ether'),{from: accounts[1]});
	  	details = await exchangeStorage.getOrder(1);
	  	assert.equal(details[0],accounts[1], "Address 1 should be maker");
	  	assert.equal(details[1], web3.toWei(10,'ether'),"Price should be 10 Ether");
	  	assert.equal(details[2], 300, "Amount listed should be 300");
	  	assert.equal(details[3], short_token.address, "Short token address should be order");
	  	assert.equal(await exchangeStorage.getOrderCount(short_token.address),2, "Short Token should have an order");

	    await exchangeStorage.setDexAddress(exchange2.address);
	    await exchange2.setDexStorageAddress(exchangeStorage.address);
	  	await exchange2.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[1]});
	  	details = await exchangeStorage.getOrder(2);
	  	assert.equal(details[0],accounts[1], "Address 1 should be maker");
	  	assert.equal(details[1], web3.toWei(10,'ether'),"Price should be 10 Ether");
	  	assert.equal(details[2], 500, "Amount listed should be 200");
	  	assert.equal(details[3], short_token.address, "Short token address should be order");
	  	assert.equal(await exchangeStorage.getOrderCount(short_token.address),3, "Short Token should have an order");
	})
	it("Test List from two exchanges", async function(){
	  	var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.approve(exchangeStorage.address,500,{from: accounts[1]});
	  	assert.equal(await short_token.allowance(accounts[1],exchangeStorage.address),500,"exchange should own tokens");
	  	await exchange.list(short_token.address,300,web3.toWei(10,'ether'),{from: accounts[1]});
	  	details = await exchangeStorage.getOrder(1);
	  	assert.equal(details[0],accounts[1], "Address 1 should be maker");
	  	assert.equal(details[1], web3.toWei(10,'ether'),"Price should be 10 Ether");
	  	assert.equal(details[2], 300, "Amount listed should be 300");
	  	assert.equal(details[3], short_token.address, "Short token address should be order");
	  	assert.equal(await exchangeStorage.getOrderCount(short_token.address),2, "Short Token should have an order");
	    await exchangeStorage.setDexAddress(exchange2.address);
	    await exchange2.setDexStorageAddress(exchangeStorage.address);
	  	var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.approve(exchangeStorage.address,500,{from: accounts[2]});;
	  	assert.equal(await short_token.allowance(accounts[2],exchangeStorage.address),500,"exchange2 should own tokens");
	  	await exchange2.list(short_token.address,500,web3.toWei(10,'ether'),{from: accounts[2]});
	  	details = await exchangeStorage.getOrder(2);
	  	assert.equal(details[0],accounts[2], "Address 1 should be maker");
	  	assert.equal(details[1], web3.toWei(10,'ether'),"Price should be 10 Ether");
	  	assert.equal(details[2], 500, "Amount listed should be 500");
	  	assert.equal(details[3], short_token.address, "Short token address should be order");
	  	assert.equal(await exchangeStorage.getOrderCount(short_token.address),3, "Short Token should have an order");
		await exchange2.list(short_token.address,200,web3.toWei(10,'ether'),{from: accounts[1]});
	  	assert.equal(await exchangeStorage.getOrderCount(short_token.address),4, "Short Token should have an order");
	})
	it("Test Buy", async function(){
	  	var receipt = await userContract.Initiate(o_startdate,1000000000000000000,{value: web3.toWei(2,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await short_token.approve(exchangeStorage.address,500,{from: accounts[1]});
	  	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	await exchange.list(short_token.address,500,web3.toWei(5,'ether'),{from: accounts[1]});
	  	await exchange.buy(1,{from: accounts[2], value:web3.toWei(5,'ether')})
	  	var bal2 = await short_token.balanceOf(accounts[2]);
	  	assert.equal(bal2-0,500,"account 2 should own tokens");
	  	var balance1_2 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0));
	  	assert.equal(balance1, balance1_2 - 5,"account 1 should get 2 ether");
	});

});