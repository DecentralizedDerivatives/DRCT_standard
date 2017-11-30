pragma solidity ^0.4.17;

interface Factory_Interface {
  function createToken(uint _supply, address _owner, bool long) public returns (address created, uint tokenratio);
  function payToken(address _party, bool long) public;
  function deployContract(address new_contract) payable public;
  function getVariables() public returns(address _oracle_address,address _operator,uint _duration,uint _multiplier,address _token_a_address,address _token_b_address,uint _start_date);
}
