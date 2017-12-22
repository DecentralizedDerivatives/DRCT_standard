/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Oracle = artifacts.require("Oracle");
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Wrapped_Ether2 = artifacts.require("Wrapped_Ether2");
var DRCT_Token = artifacts.require("DRCT_Token");
var DRCT_Token2 = artifacts.require("DRCT_Token2");
var Factory = artifacts.require("Factory");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol')

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
  var swap_add;
  var account_one = accounts[0];
  var account_two = accounts[1];
  var account_three = accounts[2];
  var account_four = accounts[3];
  var account_five = accounts[4];

  it('Setup contract for testing', async function () {
    oracle = await Oracle.deployed();
    await oracle.StoreDocument(1543881600,1000);
    await oracle.StoreDocument(1544486400,1500);
    factory = await Factory.deployed();
    await factory.setStartDate(1543881600);
    await factory.setVariables(1000000000000000,1000000000000000,7,1);
    base1 = await Wrapped_Ether.deployed();
    base2 = await Wrapped_Ether2.deployed();
    long_token = await DRCT_Token.deployed();
    short_token = await DRCT_Token2.deployed();
    userContract = await UserContract.deployed();
    deployer = await Deployer.deployed();
    await factory.setBaseTokens(base1.address,base2.address);
    await factory.setUserContract(userContract.address);
    await factory.settokens(long_token.address,short_token.address);
    await factory.setDeployer(deployer.address);
    await factory.setOracleAddress(oracle.address);
    await userContract.setFactory(factory.address);
  	assert.equal(await factory.user_contract.call(),userContract.address,"User Contract address not set correctly");
    assert.equal(await oracle.RetrieveData(1543881600),1000,"Result should equal end value");
    assert.equal(await oracle.RetrieveData(1544486400),1500,"Result should equal start value");
  });
  it("Contracts deployed successfully", async function() {
  	var receipt = await factory.deployContract({from: account_two, gas:4000000});
  	swap_add = receipt.logs[0].args._created;
  	await userContract.Initiate(swap_add,10000000000000000000,10000000000000000000,0,true,{value: web3.toWei(10,'ether'), from: account_two});
  	swap = TokenToTokenSwap.at(swap_add);
  	assert.equal(await swap.current_state.call(),1,"Current State should be 1");
  	await userContract.Enter(10000000000000000000,10000000000000000000,false,swap_add,{value: web3.toWei(10,'ether'), from: account_three});
  	assert.equal(await swap.current_state.call(),3,"Current State should be 3");
  });

  it("Tokens Traded", async function() {
  	await long_token.transfer(account_four,5000,{from:account_two});
  	await short_token.transfer(account_five,5000,{from:account_three});
  	assert.equal(await long_token.balanceOf(account_two),5000,"second balance should send tokens");
  	assert.equal(await short_token.balanceOf(account_five),5000,"half of short tokens should be sent");
  });
  it("Contracts successfully closed", async function() {
  	swap.forcePay(1,100,{from:account_one});
  	assert.equal(await swap.current_state.call(),5,"Current State should be 5");
  	for (i = 0; i < 5; i++){
	  	base1.withdraw(await base1.balanceOf(accounts[i]),{from:accounts[i]});
	  	base2.withdraw(await base2.balanceOf(accounts[i]),{from:accounts[i]});
	}
  });
});