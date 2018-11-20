/**
*This deploys wrapped_Ether, Exchange, Membership, MasterDeployer and Factory(after 
*the factory and DRCTLibrary are linked by Truffle with 2_further_deployments.js).
*/

/*
If you are not using truffle. You will have to deploy the DRCTLibrary.sol 
and link it to the Factory. 

You would linke it by following this steps:
Once you have the DRCTLibrary address, you will need to open up your 
compiled code for the Factory.sol and search for 
'__DRCTLibrary___________________________' and replace it with 
the DRCTLibrary address without the first two characters, 
meaning without the leading '0x'. This will link the Factory and 
the DRCTLibrary when you deploy the factory in the next step. 
If you use truffle(develop, migrate, test as in the quick instructions) 
to test on the Rinkeby testnet, the migrate command will automatically 
link the factory and DRCTLibrary.
*/

function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
var Wrapped_Ether = artifacts.require("WETH9");
var Factory = artifacts.require("Factory");
var Membership = artifacts.require("Membership");
var MasterDeployer = artifacts.require("MasterDeployer");
var Exchange = artifacts.require("Exchange");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");

module.exports =async function(callback) {
    let oracle;
    let factory;
    let membership;
    let masterDeployer;
    let wrapped_ether;
    let exchange;
    let drctLibrary;


        wrapped_ether = await Wrapped_Ether.new();
        console.log("wrapped_ether: ",wrapped_ether.address);
        exchange = await Exchange.new();
        console.log("exchange: ", exchange.address);
        membership = await Membership.new();
        console.log("membership: ", membership.address);
        sleep_s(5);
        masterDeployer = await MasterDeployer.new();
        console.log("masterDeployer: ", masterDeployer.address);
          sleep_s(5);
        //drctLibrary = await DRCTLibrary.new(); //uncomment to deploy a drctlibrary  
        console.log("drctLibrary:  ",drctLibrary.address)
          sleep_s(5);
        factory = await Factory.new(0);
        console.log("factory:  ",factory.address)
          sleep_s(5);
        await masterDeployer.setFactory(factory.address);
}