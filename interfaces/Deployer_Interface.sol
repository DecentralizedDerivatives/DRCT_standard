pragma solidity ^0.4.17;

//Swap Deployer functions - descriptions can be found in Deployer.sol
interface Deployer_Interface {
  function newContract(address _party) public payable returns (address created);
}
