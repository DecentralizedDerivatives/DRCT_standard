/**
*This deploys wrapped_Ether, Exchange, Membership, MasterDeployer and Factory(after 
*the factory and DRCTLibrary are linked by Truffle with 4_further_deployments2.js).
*/

/**shouold this stay?? **************/
// use ganache-cli -m waxfang
/*
Use this to deploy DDA contracts
Owner account?
AD - 0x711e2b65be4a0201bb8c8e26646366d066d42daa?
PK - e495a0d39ae99327ea09eace1f6096a5a3cddeec3b52a3ff80b719831be3d695?
*/

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
}