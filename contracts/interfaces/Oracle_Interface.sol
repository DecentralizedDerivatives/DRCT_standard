pragma solidity ^0.4.17;

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function getQuery(uint _date) external view returns(bool);
  function retrieveData(uint _date) external view returns (uint);
  function pushData() external payable;
}
