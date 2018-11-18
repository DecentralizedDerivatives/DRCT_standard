/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("WETH9");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var Membership = artifacts.require("Membership");
var MasterDeployer = artifacts.require("MasterDeployer");

contract('Oracle Test', function(accounts) {
  let oracle;
  let factory;
  let memberCoin;
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
	it("Test Oracle", async function(){
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	    assert.equal(await factory.user_contract.call(),userContract.address,"User Contract address not set correctly");
	    assert.equal(await oracle.retrieveData(o_startdate),1000,"Result should equal end value");
	    assert.equal(await oracle.retrieveData(o_enddate),1500,"Result should equal start value");
		})
  	
	it("Missed Dates", async function(){
		await oracle.StoreDocument(o_startdate + 86400,1000);
	    await oracle.StoreDocument(o_enddate + 86400,1500);
		var receipt = await userContract.Initiate(o_startdate,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	swap_add = receipt.logs[0].args._newswap;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	assert.equal(await swap.currentState(),1,"Current State should be 1");
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
		await swap.forcePay(50,{from:accounts[0]});
	  	assert.equal(await swap.currentState() - 0,2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
		assert(balance1 >= newbal - 5.5 && balance1 <= newbal - 4.5 ,"Balance1 should change correctly");
		assert(balance2 >= newbal2 + 5 && balance2 <= newbal2 + 6 ,"Balance2 should change correctly");
	});
});
