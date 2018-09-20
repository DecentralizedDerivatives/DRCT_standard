// SPDX-License-Identifier: AGPL-3.0+
const OasisDEX = artifacts.require("./maker/MatchingMarket.sol");
const FakeDAI = artifacts.require("./maker/FakeDAI.sol");
const WETH = artifacts.require("./maker/WETH9_.sol");

const Web3 = require("web3");

const web3 = new Web3();

// never close
const OASIS_DEX_CLOSE_TIME = 1000000000000000;
const WETH_DEPOSIT_AMOUNT = web3.utils.toWei("5", "ether");
const DAI_PER_WETH = 400;
const DAI_DEPOSIT_AMOUNT = 1000 * 10 ** 18;

module.exports = async (deployer, network) => {
  if (network !== "develop") {
    return; // Contracts already deployed
  }

  // Deploy all contracts
  await Promise.all([
    deployer.deploy(OasisDEX, OASIS_DEX_CLOSE_TIME),
    deployer.deploy(WETH),
    deployer.deploy(FakeDAI)
  ]);

  const [oasisDex, weth, fdai] = await Promise.all([
    OasisDEX.deployed(),
    WETH.deployed(),
    FakeDAI.deployed()
  ]);
  await oasisDex.addTokenPairWhitelist(WETH.address, FakeDAI.address);

  console.log("Setting up WETH -> DAI trading site...");

  await weth.deposit({ value: WETH_DEPOSIT_AMOUNT });
  await weth.approve(OasisDEX.address, WETH_DEPOSIT_AMOUNT);
  await oasisDex.offer(
    WETH_DEPOSIT_AMOUNT,
    WETH.address,
    WETH_DEPOSIT_AMOUNT * DAI_PER_WETH,
    FakeDAI.address,
    0
  );

  console.log("Setting up DAI -> WETH trading side...");

  // Set up DAI -> WETH trade side
  await fdai.mint(await fdai.owner(), DAI_DEPOSIT_AMOUNT);
  await fdai.approve(OasisDEX.address, DAI_DEPOSIT_AMOUNT);

  await oasisDex.offer(
    DAI_DEPOSIT_AMOUNT,
    FakeDAI.address,
    // TODO For some reason this throws an Internal JSON-RPC error when you
    // make this < 0.005
    DAI_DEPOSIT_AMOUNT * 0.005,
    WETH.address,
    0
  );
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
  it("Dai in Swap", async function() {
  });
  it("Test throw if no DAI returns", async function() {
  });
  it("Test throw if no DAI returns", async function() {
  });
  it("Test cashing out DAI", async function() {
  });
});
