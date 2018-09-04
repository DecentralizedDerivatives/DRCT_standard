/**
*This deploys wrapped_Ether, Exchange, Membership, MasterDeployer and Factory(after 
*the factory and DRCTLibrary are linked by Truffle with 2_further_deployments.js).
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

module.exports =async function(callback) {
    let oracle;
    let factory;
    let membership;
    let masterDeployer;
    let wrapped_ether;
    let exchange;


/*        wrapped_ether = await Wrapped_Ether.new();
        console.log("wrapped_ether: ",wrapped_ether.address);*/
        exchange = await Exchange.new();
        console.log("exchange: ", exchange.address);
/*        membership = await Membership.new();
        console.log("membership: ", membership.address);
        sleep_s(5);
        masterDeployer = await MasterDeployer.new();
        console.log("masterDeployer: ", masterDeployer.address);
          sleep_s(5);*/
        //factory = await Factory.deployed();
/*        factory = await Factory.new(0);
        console.log("factory:  ",factory.address)
          sleep_s(5);
        await masterDeployer.setFactory(factory.address);*/
}