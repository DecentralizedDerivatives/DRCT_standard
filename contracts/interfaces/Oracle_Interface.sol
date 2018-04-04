pragma solidity ^0.4.17;

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function getQuery(uint _date) public view returns(bool);
  function RetrieveData(uint _date) public view returns (uint);
  function pushData() public payable;
}
