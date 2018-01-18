pragma solidity ^0.4.17;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


contract Oracle is usingOraclize{

  /*Variables*/

  //Private queryId for Oraclize callback
  bytes32 private queryID;

  //Mapping of documents stored in the oracle
  mapping(uint => uint) public oracle_values;
  mapping(uint => bool) public queried;

  /*Events*/
  event DocumentStored(uint _key, uint _value);
  event newOraclizeQuery(string description);

  /*Functions*/
  function RetrieveData(uint _date) public constant returns (uint data) {
    uint value = oracle_values[_date];
    return value;
  }

 //CAlls 
  function PushData() public {
    uint _key = now - (now % 86400);
    require(queried[_key] == false);
    if (oraclize_getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize queries sent");
            queryID = oraclize_query("URL", "json(https://api.gdax.com/products/BTC-USD/ticker).price");
            queried[_key] = true;
        }
  }


  function __callback(bytes32 _oraclizeID, string _result) {
      require(msg.sender == oraclize_cbAddress() && _oraclizeID == queryID);
      uint _value = parseInt(_result,3);
      uint _key = now - (now % 86400);
      oracle_values[_key] = _value;
      DocumentStored(_key, _value);
    }


  function fund() public payable {}

  function getQuery(uint _date) public view returns(bool _isValue){
    return queried[_date];
  }

}