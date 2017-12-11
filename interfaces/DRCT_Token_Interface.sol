pragma solidity ^0.4.17;

//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount(address _swap) public constant returns (uint count);
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder);
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal);
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index);
  function createToken(uint _supply, address _owner, address _swap) public;
  function pay(address _party, address _swap) public;
  function partyCount(address _swap) public constant returns(uint count);
}
