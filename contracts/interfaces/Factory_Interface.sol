pragma solidity ^0.4.17;

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) public returns (address,address, uint);
  function payToken(address _party, address _token_add) public;
  function deployContract(uint _start_date) public payable returns (address);
   function getBase() public view returns(address);
  function getVariables() public view returns (address, uint, uint, address);
}
