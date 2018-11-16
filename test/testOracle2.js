/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var Test_Oracle2 = artifacts.require("Test_Oracle2");
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
		oracle = await Test_Oracle2.new("json(https://api.gdax.com/products/BTC-USD/ticker).price", "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price");
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
        o_startdate = 1531958400;
    	o_enddate = 1515369600;
    	balance1 = await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(1));
  		balance2 = await (web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(1));
   		await factory.deployTokenContract(o_startdate);
    	long_token_add =await factory.long_tokens(o_startdate);
	    short_token_add =await factory.short_tokens(o_startdate);
	    long_token =await DRCT_Token.at(long_token_add);
	    short_token = await DRCT_Token.at(short_token_add);
   })

	it("Test Oracle api 1st call", async function(){
	    await oracle.pushData( o_startdate, 4, 3,"0x12" );//use gdax
	    _api = await oracle.getusedAPI();//pull what exchange was used
	    console.log("api",_api); //print it
	    assert.equal(_api,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
	})	

	it("test callback", async function(){
		await oracle.pushData(o_startdate, 4, 3,"0x" );//use gdax
	    await oracle.callback(2, "0x");//value returned is 2, set called to false
		_value = await oracle.retrieveData(o_startdate);
		assert.equal(_value,2,"should equal 2");
	})	

	it("Test Oracle api alternating same date", async function(){
	    await oracle.pushData(o_startdate, 4, 3,"0x12" );//use gdax called=false 
	    _api = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange-called=true
	    _api2 = await oracle.getusedAPI();//pull what exchange was used
   	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange
	    _api3 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange
	    _api4 = await oracle.getusedAPI();//pull what exchange was used
		 await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange
	    _api5 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange
	    _api6 = await oracle.getusedAPI();//pull what exchange was used
	    assert.equal(_api,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api2,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");	    
	    assert.equal(_api3,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api4,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
     	assert.equal(_api5,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
  	    assert.equal(_api6,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");

	})

	it("Test Oracle api alternating date switch", async function(){
	    await oracle.pushData(o_startdate, 4, 3,"0x12" );//use gdax called=false 
	    _api = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange-called=true
	    _api2 = await oracle.getusedAPI();//pull what exchange was used
   	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange
	    _api3 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x12");//resend query to second exchange
	    _api4 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.callback(2, "0x12");//value returned is 2, set called to falsetest
	    await oracle.pushData(o_enddate, 4, 3,"0x13");//resend query to second exchange
	    _api5 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_enddate, 4, 3,"0x13");//resend query to second exchange
	    _api6 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_enddate, 4, 3,"0x13");//resend query to second exchange
	    _api7 = await oracle.getusedAPI();//pull what exchange was used
	    assert.equal(_api,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api2,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
	    assert.equal(_api3,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api4,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
     	assert.equal(_api5,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api6,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
		assert.equal(_api7,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");

    })

    	it("Test Oracle api alternating date switch2", async function(){
	    await oracle.pushData(o_startdate, 4, 3,"0x525f470ac7906f254acbc4c4fe0d014a181847a2" );//use gdax called=false 
	    _api = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x525f470ac7906f254acbc4c4fe0d014a181847a2");//resend query to second exchange-called=true
	    _api2 = await oracle.getusedAPI();//pull what exchange was used
   	    await oracle.pushData(o_startdate, 4, 3,"0x525f470ac7906f254acbc4c4fe0d014a181847a2");//resend query to second exchange
	    _api3 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_startdate, 4, 3,"0x525f470ac7906f254acbc4c4fe0d014a181847a2");//resend query to second exchange
	    _api4 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.callback(2, "0x525f470ac7906f254acbc4c4fe0d014a181847a2");//value returned is 2, set called to falsetest
	    await oracle.pushData(o_enddate, 4, 3,"0x2e5d4d5279a24e5c56dc297631a4fb275107d99c");//resend query to second exchange
	    _api5 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_enddate, 4, 3,"0x2e5d4d5279a24e5c56dc297631a4fb275107d99c");//resend query to second exchange
	    _api6 = await oracle.getusedAPI();//pull what exchange was used
	    await oracle.pushData(o_enddate, 4, 3,"0x2e5d4d5279a24e5c56dc297631a4fb275107d99c");//resend query to second exchange
	    _api7 = await oracle.getusedAPI();//pull what exchange was used
	    assert.equal(_api,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api2,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
	    assert.equal(_api3,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api4,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
     	assert.equal(_api5,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
        assert.equal(_api6,"json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price","API=binance");
		assert.equal(_api7,"json(https://api.gdax.com/products/BTC-USD/ticker).price","API=gdax");
    })
});
