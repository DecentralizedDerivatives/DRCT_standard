/**
*Use this for setting up contracts for testing
*Truffle migration still has to be ran to link the DRCTLibrary and Factory

*These are the two commands that need to be ran:
*truffle migrate --network rinkeby
*truffle exec scripts/Test_js_migration.js --network rinkeby
*/


var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var Membership = artifacts.require("Membership");
var MasterDeployer = artifacts.require("MasterDeployer");
var Exchange = artifacts.require("Exchange");
var Oracle = artifacts.require("Oracle");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
const TokenToTokenSwap = artifacts.require('./TokenToTokenSwap.sol');
const DRCT_Token = artifacts.require('./DRCT_Token.sol');
var o_startdate =1531440000;
var hdate = "07/13/2018"; //human readable date

module.exports =async function(callback) {
    let factory;
    let membership;
    let masterDeployer;
    let wrapped_ether;
    let exchange;
        wrapped_ether = await Wrapped_Ether.new();
        console.log("wrapped_ether: ",wrapped_ether.address);
        exchange = await Exchange.new();
        console.log("exchange: ", exchange.address);
        membership = await Membership.new();
        console.log("membership: ", membership.address);
        masterDeployer = await MasterDeployer.new();
        console.log("masterDeployer: ", masterDeployer.address);
        factory = await Factory.deployed();
        console.log("factory:  ",factory.address)
        await masterDeployer.setFactory(factory.address);

    var swapFee = 0;
    var  duration = 7;

    var type = "BTC/USD";
    var _oracle_api = "json(https://api.gdax.com/products/BTC-USD/ticker).price";
    var _oracle_api2 = "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price";
    var multiplier = 1;

    var type2 = "ETH/USD";
    var _oracle_api3 = "json(https://api.gdax.com/products/ETH-USD/ticker).price";
    var _oracle_api4 = "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price";
    var multiplier2 = 5;


    let masterDeployer1 = await MasterDeployer.at(masterDeployer.address);
    let factory1;
    let base;
    let deployer;
    let userContract;
    let oracle;
      let res = await masterDeployer1.deployFactory();
      res = res.logs[0].args._factory;
      factory1 = await Factory.at(res);
      await factory1.setVariables(1000000000000000, duration, multiplier, swapFee);
      await factory1.setMemberContract(membership.address);
      await factory1.setWhitelistedMemberTypes([0]);
      base = await Wrapped_Ether.at(wrapped_ether.address);
      userContract = await UserContract.new();
      deployer = await Deployer.new(factory1.address);
      oracle = await Oracle.new(_oracle_api,_oracle_api2);
      await factory1.setBaseToken(base.address);
      await factory1.setUserContract(userContract.address);
      await factory1.setDeployer(deployer.address);
      await factory1.setOracleAddress(oracle.address);
      await userContract.setFactory(factory1.address);


    let factory2;
    let base2;
    let deployer2;
    let userContract2;
    let oracle2;
      let res2 = await masterDeployer1.deployFactory();
      res2 = res2.logs[0].args._factory;
      factory2 = await Factory.at(res2);
      await factory2.setVariables(1000000000000000, duration, multiplier2, swapFee);
      await factory2.setMemberContract(membership.address);
      await factory2.setWhitelistedMemberTypes([0]);
      base2 = await Wrapped_Ether.at(wrapped_ether.address);
      userContract2 = await UserContract.new();
      deployer2 = await Deployer.new(factory2.address);
      oracle2 = await Oracle.new(_oracle_api3,_oracle_api4);
      await factory2.setBaseToken(base.address);
      await factory2.setUserContract(userContract.address);
      await factory2.setDeployer(deployer.address);
      await factory2.setOracleAddress(oracle.address);
      await userContract2.setFactory(factory2.address);

    console.log("MasterDeployer, Type,duration, multiplier, swapFee, Factory, Oracle, Deployer, UserContract, BaseToken")
    var  ar = [masterDeployer.address,type,duration,multiplier, swapFee, factory1.address, oracle.address, deployer.address, userContract.address, base.address];
    var  ar2 = [masterDeployer.address,type2,duration,multiplier2, swapFee, factory2.address, oracle2.address, deployer2.address, userContract2.address, base2.address];
    console.log(ar.join(', '));
    console.log(ar2.join(', '));

    console.log('token date: ',hdate)
    await factory1.deployTokenContract(o_startdate);
    var long_token_add =await factory1.long_tokens(o_startdate);
    var short_token_add =await factory1.short_tokens(o_startdate);
    console.log('Long Token BTC/USD: ',long_token_add);
    console.log('Short Token BTC/USD: ',short_token_add);

    await factory2.deployTokenContract(o_startdate);
    var long_token_add2 =await factory2.long_tokens(o_startdate);
    var short_token_add2 =await factory2.short_tokens(o_startdate);
    console.log('Long Token ETH/USD: ',long_token_add2);
    console.log('Short Token ETH/USD: ',short_token_add2);



}