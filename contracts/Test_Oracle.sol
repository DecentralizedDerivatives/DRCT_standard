pragma solidity ^0.4.17;

//The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is updated by an off chain calculation by DDA.  Methodology can be found at www.github.com/DecentralizedDerivatives/Oracles
contract Test_Oracle {

  /*Variables*/
  //Owner of the oracle
  address private owner;
  //Mapping of documents stored in the oracle
  mapping(uint => uint) oracle_values;

  /*Events*/
  event DocumentStored(uint _key, uint _value);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  //Constructor - Sets owner
  function Test_Oracle() public {
    owner = msg.sender;
  }

  //Allows the owner of the Oracle to store a document in the oracle_values mapping. Documents
  //represent underlying values at a specified date (key).
  function StoreDocument(uint _key, uint _value) public onlyOwner() {
    oracle_values[_key] = _value;
    DocumentStored(_key, _value);
  }

  //Allows for the viewing of oracle data
  function RetrieveData(uint _date) public constant returns (uint data) {
    return oracle_values[_date];
  }

  //set a new owner of the contract
  function setOwner(address _new_owner) public onlyOwner() { owner = _new_owner; }
}