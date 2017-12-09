pragma solidity ^0.4.17;

import "./TokenToTokenSwap.sol";

//Swap Deployer Contract
contract Deployer {
  address owner;
  address factory;

  function Deployer(address _factory) public {
    factory = _factory;
    owner = msg.sender;
  }

  function newContract(address _party, address user_contract) public returns (address created) {
    require(msg.sender == factory);
    address new_contract = new TokenToTokenSwap(factory, _party, user_contract);
    return new_contract;
  }

   function setVars(address _factory, address _owner) public {
    require (msg.sender == owner);
    factory = _factory;
    owner = _owner;
  }
}
