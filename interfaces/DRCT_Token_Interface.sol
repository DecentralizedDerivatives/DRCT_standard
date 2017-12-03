pragma solidity ^0.4.17;

//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount() public constant returns (uint count);
  function getHolderByIndex(uint _ind) public constant returns (address holder);
  function getBalanceByIndex(uint _ind) public constant returns (uint bal);
  function getIndexByAddress(address _owner) public constant returns (uint index);
  function createToken(uint _supply, address _owner) public;
  function pay(address _party) public;
}
