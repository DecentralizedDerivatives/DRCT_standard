var Oracle = artifacts.require("Oracle");



module.exports =async function(callback) {
  await oracle.PushData();
}
