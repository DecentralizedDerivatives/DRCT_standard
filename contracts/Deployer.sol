pragma solidity ^0.4.17;

import "./TokenToTokenSwap.sol";

//Swap Deployer Contract-- purpose is to save gas for deployment of Factory contract
contract Deployer {
  address owner;
  address factory;

  function Deployer(address _factory) public {
    factory = _factory;
    owner = msg.sender;
  }

  function newContract(address _party, address user_contract, uint _start_date) public returns (address) {
    require(msg.sender == factory);
    address new_contract = new TokenToTokenSwap(factory, _party, user_contract, _start_date);
    return new_contract;
  }

   function setVars(address _factory, address _owner) public {
    require (msg.sender == owner);
    factory = _factory;
    owner = _owner;
  }
}
