/****Uncomment the body below to run this with Truffle migrate for truffle testing*/

var Factory = artifacts.require("./Factory.sol");
var DRCTLibrary = artifacts.require("./libraries/DRCTLibrary.sol");

/****Uncomment the body to run this with Truffle migrate for truffle testing*/

/**
*@dev Use this for setting up contracts for testing 
*this will link the Factory and DRCT Library

*These commands that need to be ran:
*truffle migrate --network rinkeby
*truffle exec scripts/Migrate_1.js --network rinkeby
*truffle exec scripts/Migrate_2.js --network rinkeby
*/
function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
/****Uncomment the body below to run this with Truffle migrate for truffle testing*/
module.exports = function(deployer) {
    DRCTLibrary.deployed().then(function(drct){
        return Factory.link(DRCTLibrary,drct.address);
        sleep_s(5);
    }).then(function() {
        return deployer.deploy(Factory);
    })
}


/*module.exports = function(deployer) {
	deployer.deploy(DRCTLibrary);
	deployer.link(DRCTLibrary,Factory);
	deployer.deploy(Factory);
}
*/
/****Uncomment the body to run this with Truffle migrate for truffle testing*/