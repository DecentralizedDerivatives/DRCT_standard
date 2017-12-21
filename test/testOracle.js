var Oracle = artifacts.require("Oracle");

var startDate = 1;
var endDate = 2;
var startVal = 1000;
var endVal = 2000;


contract('Oracle', function(accounts) {
  let oracle;
  beforeEach('setup contract for each test', async function () {
    oracle = await Oracle.deployed();
    await oracle.StoreDocument(startDate,startVal);
    await oracle.StoreDocument(endDate,endVal)
  })
  it("Set values", async function() {
      assert.equal(await oracle.RetrieveData(startDate),startVal,"Result should equal end value");
      assert.equal(await oracle.RetrieveData(endDate),endVal,"Result should equal start value");
    })
  });