var Oracle = artifacts.require("Oracle");



module.exports =async function(callback) {
  let oracle = await Oracle.deployed();
  await oracle.fund({value: web3.toWei(.1,'ether')});
  await oracle.PushData();
}
