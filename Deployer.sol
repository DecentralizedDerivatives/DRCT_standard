pragma solidity ^0.4.17;

import "./TokenToTokenSwap.sol";

//Swap Deployer Contract
contract Deployer {
  address owner;

  function Deployer(address _factory) public {
    owner = _factory;
  }

  //TODO - payable?
  function newContract(address _party) public payable returns (address created) {
    require(msg.sender == owner);
    address new_contract = new TokenToTokenSwap(owner, _party);
    return new_contract;
  }
}
