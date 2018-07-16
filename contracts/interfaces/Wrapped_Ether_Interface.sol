pragma solidity ^0.4.24;

//ERC20 function interface with create token and withdraw
interface Wrapped_Ether_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
  function withdraw(uint _value) external;
  function createToken() external;

}
