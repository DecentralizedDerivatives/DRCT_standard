pragma solidity ^0.4.17;

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function RetrieveData(uint _date) public view returns (uint data);
}
