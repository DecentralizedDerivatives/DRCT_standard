pragma solidity ^0.4.17;

interface DRCT_Interface {

  //ERC20 functions
  function totalSupply() public constant returns (uint total_supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
  function approve(address _spender, uint _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint amount);


  //DRCT_Token functions - descriptions can be found in DRCT_Token.sol
  function addressCount() public constant returns (uint count);
  function getHolderByIndex(uint _ind) public constant returns (address holder);
  function getBalanceByIndex(uint _ind) public constant returns (uint bal);
  function getIndexByAddress(address _owner) public constant returns (uint index);
  function createToken(uint _supply, address _owner) public;
  function pay(address _party) public;

  //Events
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event StateChanged(bool _success, string _message);

}
