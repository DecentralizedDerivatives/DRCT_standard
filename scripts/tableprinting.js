
var MasterDeployer = artifacts.require("MasterDeployer")
var Oracle = artifacts.require("Oracle")

oracle_add = "";


module.exports =async function(callback) {
      let oralce = Oracle.at(oracle_add);
      await oracle.pushData({value:10000000000000000});
      console.log(await masterDeployer.getFactoryCount());

}