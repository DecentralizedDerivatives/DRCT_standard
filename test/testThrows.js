/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle = artifacts.require("Test_Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
var Tokendeployer = artifacts.require("Tokendeployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');


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


contract('Contracts', function(accounts) {
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
	    await expectThrow(factory.createToken(10000000000000000000,accounts[2],o_startdate,{from: accounts[2]}));
	    await expectThrow(factory.deployTokenContract(o_startdate,true,{from: accounts[2]}));
	    await expectThrow(factory.setBaseToken(accounts[2],{from: accounts[2]}));
   })
        it("Throw testing upmove", async function() {
	  	await oracle.StoreDocument(o_startdate,1000);
	    await oracle.StoreDocument(o_enddate,1500);
	  	var receipt = await factory.deployContract(o_startdate,{from: accounts[1]});
	  	swap_add = receipt.logs[0].args._created;
	  	swap = await TokenToTokenSwap.at(swap_add);
	  	await expectThrow(userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[2]}));
	  	await userContract.Initiate(swap_add,10000000000000000000,{value: web3.toWei(20,'ether'), from: accounts[1]});
	  	await short_token.transfer(accounts[2],10000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
	  	await long_token.transfer(accounts[3],5000,{from:accounts[1]});
	  	await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
	  	await short_token.transfer(accounts[4],5000,{from:accounts[2]});
	  	await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
		await swap.forcePay(1,100,{from:accounts[0]});
		await expectThrow(swap.forcePay(1,100,{from:accounts[0]}));
	  	assert.equal(await swap.current_state.call(),2,"Current State should be 2");
	  	for (i = 0; i < 5; i++){
		  	await base.withdraw(await base.balanceOf(accounts[i]),{from:accounts[i]});
		}
		await expectThrow(base.withdraw(await 10000000000000000,{from:accounts[1]}));
		var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
		var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
		});

});