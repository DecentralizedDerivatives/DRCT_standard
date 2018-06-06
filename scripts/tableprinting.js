
var MasterDeployer = artifacts.require("MasterDeployer")


module.exports =async function(callback) {
      let masterDeployer = await MasterDeployer.deployed();
      console.log(await masterDeployer.getFactoryCount());
      console.log(await masterDeployer.getFactorybyIndex(2))
}