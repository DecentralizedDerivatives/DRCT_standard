pragma solidity ^0.4.17;

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface TokenToTokenSwap_Interface {
  function createSwap(uint _amount, address _senderAdd) external;
}
