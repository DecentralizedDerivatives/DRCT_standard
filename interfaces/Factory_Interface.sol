pragma solidity ^0.4.17;

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _owner, bool long) public returns (address created, uint tokenratio);
  function payToken(address _party, bool long) public;
   function deployContract() public payable returns (address created);
  function getVariables() public view returns (address oracle_addr, address factory_operator, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr, uint swap_start_date);
}
