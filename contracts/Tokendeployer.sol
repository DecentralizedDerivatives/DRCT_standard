pragma solidity ^0.4.17;

import "./DRCT_Token.sol";

//Swap Deployer Contract-- purpose is to save gas for deployment of Factory contract
contract Tokendeployer {
  address owner;
  address public factory;

  function Tokendeployer(address _factory) public {
    factory = _factory;
    owner = msg.sender;
  }

  function newToken() public returns (address created) {
    require(msg.sender == factory);
    address new_token = new DRCT_Token(factory);
    return new_token;
  }

   function setVars(address _factory, address _owner) public {
    require (msg.sender == owner);
    factory = _factory;
    owner = _owner;
  }
}
