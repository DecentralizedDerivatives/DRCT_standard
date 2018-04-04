pragma solidity ^0.4.17;

//ERC20 function interface with create token and withdraw
interface Wrapped_Ether_Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address _owner) public constant returns (uint);
  function transfer(address _to, uint _amount) public returns (bool);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool);
  function approve(address _spender, uint _amount) public returns (bool);
  function allowance(address _owner, address _spender) public constant returns (uint);
  function withdraw(uint _value) public;
  function CreateToken() public;

}
