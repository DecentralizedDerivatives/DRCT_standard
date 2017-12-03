pragma solidity ^0.4.17;

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface TokenToTokenSwap_Interface {
  function CreateSwap(uint _amount_a, uint _amount_b, bool _sender_is_long) public payable;
  function EnterSwap(uint _amount_a, uint _amount_b, bool _sender_is_long) public;
}
