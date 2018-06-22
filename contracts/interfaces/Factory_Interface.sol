pragma solidity ^0.4.21;

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) external returns (address,address, uint);
  function payToken(address _party, address _token_add) external;
  function deployContract(uint _start_date) external payable returns (address);
   function getBase() external view returns(address);
  function getVariables() external view returns (address, uint, uint, address,uint);
  function isWhitelisted(address _member) external view returns (bool);
}
