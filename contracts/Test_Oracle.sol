pragma solidity ^0.4.17;

/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/
contract Test_Oracle {

    /*Variables*/
    //Owner of the oracle
    address private owner;
    //Mapping of documents stored in the oracle
    mapping(uint => uint) oracle_values;
    mapping(uint => bool) public queried;

    /*Events*/
    event DocumentStored(uint _key, uint _value);

    /*Modifiers*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
    function Test_Oracle() public {
        owner = msg.sender;
    }

    /**
    *@dev Allows the owner of the Oracle to store a document in the oracle_values mapping. 
    *Documents represent underlying values at a specified date (_key).
    *@param _key a specified date
    *@param _value the value for the specified date
    */
    function StoreDocument(uint _key, uint _value) public onlyOwner() {
        oracle_values[_key] = _value;
        DocumentStored(_key, _value);
        queried[_key] = true;
    }

    /**
    *@dev Function pushData is here for testing purposes
    */
    function pushData() public view{
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
    function RetrieveData(uint _date) public constant returns (uint) {
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