pragma solidity ^0.4.23;

import "oraclize-api/usingOraclize.sol";

/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/

contract Oracle is usingOraclize{
    /*Variables*/
    //Private queryId for Oraclize callback
    bytes32 private queryID;
    string public API;

    /*Structs*/
    struct QueryInfo {
        uint value;
        bool queried;
        uint date;
    }  
    //Mapping of documents stored in the oracle
    mapping(uint => bytes32) public queryIds;
    mapping(bytes32 => QueryInfo ) public info;

    /*Events*/
    event DocumentStored(uint _key, uint _value);
    event newOraclizeQuery(string description);

    /*Functions*/
    /**
    *@dev Constructor, sets public api string
    *e.g. "json(https://api.gdax.com/products/BTC-USD/ticker).price"
    * or "json(https://api.gdax.com/products/ETH-USD/ticker).price"
    */
     constructor(string _api) public{
        API = _api;
    }

    /**
    *@dev RetrieveData - Returns stored value by given key
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    */
    function retrieveData(uint _date) public constant returns (uint) {
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.value;
    }

    /**
    *@dev PushData - Sends an Oraclize query for entered API
    */
    function pushData() public payable{
        uint _key = now - (now % 86400);
        QueryInfo storage currentQuery = info[queryIds[_key]];
        require(currentQuery.queried == false);
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize queries sent");
            queryID = oraclize_query("URL", API);
            queryIds[_key] = queryID;
            currentQuery.queried = true;
            currentQuery.date = _key;
        }
    }

    /**
    *@dev Used by Oraclize to return value of PushData API call
    *@param _oraclizeID unique oraclize identifier of call
    *@param _result Result of API call in string format
    */
    function __callback(bytes32 _oraclizeID, string _result) public {
        QueryInfo storage currentQuery = info[_oraclizeID];
        require(msg.sender == oraclize_cbAddress() && _oraclizeID == queryID);
        currentQuery.value = parseInt(_result,3);
        if(currentQuery.value == 0){
            currentQuery.value = 1;
        }
        emit DocumentStored(currentQuery.date, currentQuery.value);
    }

    /**
    *@dev Allows the contract to be funded in order to pay for oraclize calls
    */
    function fund() public payable {
      
    }

    /**
    *@dev Determine if the Oracle was queried
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    *@return true or false based upon whether an API query has been 
    *initialized (or completed) for given date
    */
    function getQuery(uint _date) public view returns(bool){
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.queried;
    }
}