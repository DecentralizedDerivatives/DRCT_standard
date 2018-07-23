pragma solidity ^0.4.24;

/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/
contract Test_Oracle2 {

    /*Variables*/
    
    address private owner;
    bytes32 private queryID;
    string public usedAPI;
    string public API;
    string public API2;

    /*Structs*/
    struct QueryInfo {
        uint value;
        bool queried;
        uint date;
        uint calledTime;
        bool called;
    }  
    //Mapping of documents stored in the oracle
    mapping(uint => bytes32) public queryIds;
    mapping(bytes32 => QueryInfo ) public info;

    //Mapping of documents stored in the oracle
    mapping(uint => uint) internal oracle_values;
    mapping(uint => bool) public queried;

    /*Events*/
    event DocumentStored(uint _key, uint _value);
    event newOraclizeQuery(string description);
    event called(bool _wascalled);

    /*Modifiers*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    /**
    *@dev Constructor, sets two public api strings
    *e.g. "json(https://api.gdax.com/products/BTC-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
    * or "json(https://api.gdax.com/products/ETH-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
    */
     constructor(string _api, string _api2) public{
        owner = msg.sender;
        API = _api;
        API2 = _api2;
    }

    /**
    *@dev Allows the owner of the Oracle to store a document in the oracle_values mapping. Documents
    *represent underlying values at a specified date (key).
    */
    function StoreDocument(uint _key, uint _value) public onlyOwner() {
        if(_value == 0){
            _value = 1;
        }
        oracle_values[_key] = _value;
        emit DocumentStored(_key, _value);
        queried[_key] = true;
    }

    /**
    *@dev PushData - Sends an Oraclize query for entered API
    */
    function pushData(uint _key, uint _bal, uint _cost, bytes32 _queryID) public payable {
        uint _calledTime = now;
        QueryInfo storage currentQuery = info[queryIds[_key]];
        require(currentQuery.queried == false  && currentQuery.calledTime == 0 || 
            currentQuery.calledTime != 0  &&
            currentQuery.value == 0);

        if ( _cost > _bal) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH");
        } else {
            emit newOraclizeQuery("Oraclize queries sent");
            emit called(currentQuery.called); 
            if (currentQuery.called == false){
                usedAPI=API;
            //    currentQuery.called = true;
            } else if (currentQuery.called == true ){
                usedAPI=API2;   
            //    currentQuery.called = false;          
            }
            queryID = _queryID;
            queryIds[_key] = queryID;
            currentQuery = info[queryIds[_key]];
            currentQuery.queried = true;
            currentQuery.date = _key;
            currentQuery.calledTime = _calledTime;
            currentQuery.called = !currentQuery.called;
        }
    }
    

    /**
    *@dev Used to test callback
    *@param _oraclizeID unique oraclize identifier of call
    *@param _result Result of API call in string format
    */
     function callback(uint _result, bytes32 _oraclizeID) public {
        QueryInfo storage currentQuery = info[_oraclizeID];
        require(_oraclizeID == queryID);
        currentQuery.value = _result;
        currentQuery.called = false; 
        if(currentQuery.value == 0){
            currentQuery.value = 1;
        }
        emit DocumentStored(currentQuery.date, currentQuery.value);
    } 

    /*
    * gets API used for tests
    */
    function getusedAPI() public view returns(string){
        return usedAPI;
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

    /**
    *@dev RetrieveData - Returns stored value by given key
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    *@return oracle_values for the date
    */
    function retrieveData(uint _date) public constant returns (uint) {
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.value;
    }


    /**
    *@dev Set the new owner of the contract or test oracle?
    *@param _new_owner for the oracle? 
    */
    function setOwner(address _new_owner) public onlyOwner() {
        owner = _new_owner; 
    }
}