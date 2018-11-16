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

contract('Deployer Tests', function(accounts) {
  let oracle;
  let factory;
  let base1;
  let deployer;
  let userContract;
  let long_token;
  let short_token;
  let swap;
  var swap_add;
  let memberCoin;
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
  	it("Deploy Multiple Factories", async function(){
		for(var i = 0;i<10;i++){
			await masterDeployer.deployFactory(0);
		}
		assert.equal(await masterDeployer.getFactoryCount() - 0 ,11,"Ten New Factories should be created");
		let res = await masterDeployer.deployFactory(0);
	    res = res.logs[0].args._factory;
	    assert.equal(await masterDeployer.getFactorybyIndex(12),res,"Getting the factory should work");
	});


   	 it("Remove Factory", async function(){
  	   	let res = await masterDeployer.deployFactory(0);
	    res = res.logs[0].args._factory;
	    var _res = await masterDeployer.factory_index.call(res);
	    assert.equal(_res.c[0],2,"Factory Should be there");
		for(var i = 0;i<10;i++){
			await masterDeployer.deployFactory(0);
		}
		await masterDeployer.removeFactory(res);
		var _res = await masterDeployer.factory_index.call(res);
	    assert.equal(_res.c[0],0,"Factory Should be removed");
	});
   	 it("Gas Calculation",async function(){
   	 	balance1 = await (web3.eth.getBalance(accounts[0]));
   	 	await deployer.newContract(factory.address,accounts[0],o_startdate);
   	 	balance2 = await (web3.eth.getBalance(accounts[0]));
   	 	console.log('gas for swap deployment (wei)',balance1-balance2);
   	 });


});
