pragma solidity ^0.4.21;

/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/
contract Test_Oracle {

    /*Variables*/
    //Owner of the oracle
    address private owner;
    string public API;
    //Mapping of documents stored in the oracle
    mapping(uint => uint) internal oracle_values;
    mapping(uint => bool) public queried;

    /*Events*/
    event DocumentStored(uint _key, uint _value);

    /*Modifiers*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
    *@dev Constructor - Sets owner
    */
     constructor(string _api) public {
        owner = msg.sender;
        API = _api;
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

    function pushData() public pure {
        //here for testing purposes
    }

    /**
    *@dev Determine if the Oracle was queried
    *@param _date a specified date
    *@return whether or not the Oracle was queried on the specified date
    */    
    function getQuery(uint _date) public view returns(bool){
        return queried[_date];
    }

    /**
    *@dev Allows for the viewing of Oracle data
    *@param _date specified date being queried from the Oracle data
    *@return oracle_values for the date
    */
    function retrieveData(uint _date) public constant returns (uint) {
        return oracle_values[_date];
    }

    /**
    *@dev Set the new owner of the contract or test oracle?
    *@param _new_owner for the oracle? 
    */
    function setOwner(address _new_owner) public onlyOwner() {
        owner = _new_owner; 
    }
}