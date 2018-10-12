
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
// SPDX-License-Identifier: AGPL-3.0+
const MatchingMarket = artifacts.require("./dai/MatchingMarket.sol");

      // never close
const OASIS_DEX_CLOSE_TIME = 1000000000000000;
const WETH_DEPOSIT_AMOUNT = web3.toWei("25", "ether");
const DAI_PER_WETH = 1;
const DAI_DEPOSIT_AMOUNT = web3.toWei("25", "ether");

contract('DaiTests', function(accounts) {
  let oracle;
  let factory;
  let wrappedEther;
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
  let fdai;
  let oasisDex;

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
      wrappedEther = await Wrapped_Ether.new();
      userContract = await UserContract.new();
      deployer = await Deployer.new(factory.address);
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
      console.log('Starting deployment');
      oasisDex = await MatchingMarket.new(OASIS_DEX_CLOSE_TIME)
      console.log('oDex',oasisDex.address);
      fdai = await Wrapped_Ether.new();
      await oasisDex.addTokenPairWhitelist(wrappedEther.address,fdai.address);
      console.log("Setting up WETH -> DAI trading site...");
      await wrappedEther.deposit({value: WETH_DEPOSIT_AMOUNT });
      await wrappedEther.approve(oasisDex.address, WETH_DEPOSIT_AMOUNT);
            console.log('Inputs',wrappedEther.address,fdai.address);
      var o1 =  await oasisDex.offer(WETH_DEPOSIT_AMOUNT,wrappedEther.address,WETH_DEPOSIT_AMOUNT * DAI_PER_WETH,fdai.address,0,false);
      console.log(o1.logs[0].args);
      console.log("Setting up DAI -> WETH trading side...");
      // Set up DAI -> WETH trade side
      await fdai.deposit({value: DAI_DEPOSIT_AMOUNT});
      await fdai.approve(oasisDex.address, DAI_DEPOSIT_AMOUNT);
      var o2 = await oasisDex.offer(DAI_DEPOSIT_AMOUNT,fdai.address,DAI_DEPOSIT_AMOUNT*1.01,wrappedEther.address,0,false);
      console.log(o2.logs[0].args);
      await userContract.setWrappedEtherAddress(wrappedEther.address);
      await userContract.setDaiAddress(fdai.address);
      await userContract.setDEXAddress(oasisDex.address);
            await factory.setBaseToken(fdai.address);
   })

  it("Dai in Swap", async function() {

      await oracle.StoreDocument(o_startdate,1000);
      await oracle.StoreDocument(o_enddate,1500);
      console.log('Inputs',fdai.address,wrappedEther.address);
      console.log(await oasisDex.getBestOffer(fdai.address,wrappedEther.address));
            await wrappedEther.deposit({value: WETH_DEPOSIT_AMOUNT });
      await wrappedEther.approve(oasisDex.address, WETH_DEPOSIT_AMOUNT);
      let res = await userContract.InitiateWithDai(o_startdate,10000000000000000000,10000000000000000000 * .98,{value:web3.toWei(20,'ether'), from: accounts[1]});
      res = res.logs[0].args._newswap;
      swap = await TokenToTokenSwap.at(res);
      assert.equal(await swap.currentState(),1,"Current State should be 1");
      await short_token.transfer(accounts[2],10000,{from:accounts[1]});
      await web3.eth.sendTransaction({from:accounts[2],to:accounts[1], value:web3.toWei(10, "ether")});
      await long_token.transfer(accounts[3],5000,{from:accounts[1]});
      await web3.eth.sendTransaction({from:accounts[3],to:accounts[1], value:web3.toWei(5, "ether")});
      await short_token.transfer(accounts[4],5000,{from:accounts[2]});
      await web3.eth.sendTransaction({from:accounts[4],to:accounts[2], value:web3.toWei(5, "ether")});
      assert.equal(await long_token.balanceOf(accounts[1]),5000,"second balance should send tokens");
      assert.equal(await short_token.balanceOf(accounts[4]),5000,"half of short tokens should be sent");
    await swap.forcePay(50,{from:accounts[0]});
      assert.equal(await swap.currentState(),2,"Current State should be 2");
      for (i = 0; i < 5; i++){
        await userContract.CashOutDai(await base.balanceOf(accounts[i]),{from:accounts[i]});
    }
    var newbal = eval(await (web3.fromWei(web3.eth.getBalance(accounts[1]), 'ether').toFixed(0)));
    var newbal2 = eval(await web3.fromWei(web3.eth.getBalance(accounts[2]), 'ether').toFixed(0));
    assert(balance1 >= newbal - 3 && balance1 <= newbal - 2 ,"Balance1 should change correctly");
    assert(balance2 >= newbal2 + 2 && balance2 <= newbal2 + 3 ,"Balance2 should change correctly");


  });
  /*it("Test throw if no DAI returns", async function() {
  });
  it("Test throw if no DAI returns", async function() {
  });
  it("Test cashing out DAI", async function() {
  });*/
});
