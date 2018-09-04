/**
*This deploys MasterDeployer and Factory(after 
*the factory and DRCTLibrary are linked by updating the Factory.json 
*with the DRCTLibrary address. Note: remove the 0x from the DRCTLibrary
*address when updating the .json file).
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
var Wrapped_Ether = artifacts.require("Wrapped_Ether");
var Factory = artifacts.require("Factory");
var Membership = artifacts.require("Membership");
var MasterDeployer = artifacts.require("MasterDeployer");
var Exchange = artifacts.require("Exchange");

var Oracle = artifacts.require("Oracle");
var UserContract= artifacts.require("UserContract");
var Deployer = artifacts.require("Deployer");
/**
*@dev Update the addresses below. get these addresses from the log after running 
*4_Admin_setup.js
*/
var swapFee = 500; //.05%

var type = "BTC/USD";
var  duration = 7;
var multiplier = 1;
//var _oracle = "0x98cb5fc6ce37b4c4dceab510a56af254c551b705"; //btc rinkeby
var _oracle = "0x98d3c4adb5c171012d3f1fde32ed8dca488a2b34"; //MAINNET btc mainnet

/*var type = "ETC/USD";
var  duration = 7;
var multiplier = 5;
//var _oracle = "0xd1864d6e55c0fb2b64035cfbc5a5c2f07e9cff89";//eth rinkeby
var _oracle = "0xc479e26a7237c1839f44a09843699597ef23e2c3";//MAINNET eth mainnet
*/
/*var _member = "0x620b6b6ac75ad9234eb6c533688ddd8a5948650e";//rinkeby 0x50d9bf95bf09d6ea9812da2763eac32d21ca31d5
var _wrapped = "0x6248cb8a316fc8f1488ce56f6ea517151923531a";//rinkeby
var _master = "0xe8327b94aba6fbc3a95f7ffaf8dd568e6cd36616"; //rinkeby
//var _factoryDud = "0xe007b01706fd3129251d7e9770346c358ef77f5f"; //rinkeby*/

var _member = "0xd33615c5ea5d703f06d237f6c56ff2400b564c77";//MAINNET
var _wrapped = "0xf2740c75f221788cf78c716b953a7f1c769d49b9";//MAINNET
var _master = "0xcd8e11dad961dad43cc3de40df918fe808cbda74"; //MAINNET
//var _factoryDud = "0xa58d1ea78cd1b610d5dc08c57b1f9fea185061cd"; //MAINNET


module.exports =async function(callback) {
    let oracle;
    let factoryDud;
    let factory;
    let membership;
    let masterDeployer;
    let wrapped_ether;
    let exchange;

    console.log("Type,duration, multiplier, swapFee")
    var  ar = [type,duration,multiplier, swapFee];
    console.log(ar.join(', '));

      masterDeployer = await MasterDeployer.at(_master);
      console.log("masterDeployer: ", masterDeployer.address);
      sleep_s(5);
      let res = await masterDeployer.deployFactory(0);
      sleep_s(10);
      res = res.logs[0].args._factory;
      factory = await Factory.at(res);
      console.log('Factory : ',factory.address);
      sleep_s(40);

      //factory = await Factory.at("");
      await factory.setVariables(1000000000000000, duration, multiplier, swapFee);
      console.log("set variables");
      sleep_s(45);
      await factory.setMemberContract(_member);
      console.log("set membercontract");
      sleep_s(10);
      await factory.setBaseToken(_wrapped);
      console.log("set base token-wrapped.sol address");
      sleep_s(10);

      userContract = await UserContract.new();
      console.log('UserContract: ',userContract.address);
      sleep_s(60);
      //userContract = await UserContract.at("");
      await userContract.setFactory(factory.address);
      console.log("set factory address for user contract");
      sleep_s(30);
      await factory.setUserContract(userContract.address);
      console.log("set user contract");
      sleep_s(10);

      deployer = await Deployer.new(factory.address);
      console.log('Deployer: ',deployer.address);
      sleep_s(60);
      //deployer = await Deployer.at("");
      await factory.setDeployer(deployer.address);
      console.log("set deployer");
      sleep_s(10);
      await factory.setOracleAddress(_oracle);
      console.log('Oracle: ',_oracle);
      sleep_s(10);
        

}




