pragma solidity ^0.4.17;

interface Factory_Interface {
  function createToken(uint _supply, address _owner, bool long) public returns (address created, uint tokenratio);
  function payToken(address _party, bool long) public;
}
