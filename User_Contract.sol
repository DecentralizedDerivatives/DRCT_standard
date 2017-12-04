pragma solidity ^0.4.17;


import "./interfaces/TokenToTokenSwap_Interface.sol";
import "./interfaces/Factory.sol";
import "./WrappedEther.sol";
import "./libraries/SafeMath.sol";



contract UserContract{
  using SafeMath for uint256;
  TokenToTokenSwap_Interface swap;
  Wrapped_Ether token;
  Factory_Interface factory;

  address public factory_address;
  address owner;
  
  function UserContract(){
      owner = msg.sender;
  }

  function Initiate(address _swapadd, uint _amounta, uint _amountb, uint _premium, bool _isLong) payable public returns (bool) {
    require(msg.value == _amounta.add(_premium));
    swap = TokenToTokenSwap_Interface(_swapadd);
    swap.CreateSwap.value(_premium)(_amounta, _amountb, _isLong, msg.sender);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_a_address);
    token.CreateToken.value(msg.value)();
    bool success = token.transfer(_swapadd,msg.value);
    return success;
  }

  function Enter(uint _amounta, uint _amountb, bool _isLong, address _swapadd) payable public returns(bool){
    require(msg.value ==_amountb);
    swap = TokenToTokenSwap_Interface(_swapadd);
    swap.EnterSwap(_amounta, _amountb, _isLong,msg.sender);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_b_address);
    token.CreateToken.value(msg.value)();
    bool success = token.transfer(_swapadd,msg.value);
    swap.createTokens();
    return success;
  }


  function setFactory(address _factory_address) public {
      require (msg.sender == owner);
    factory_address = _factory_address;
    factory = Factory_Interface(factory_address);
  }

  function setOwner(address _new_owner) public{ 
    require (msg.sender == owner); 
    owner = _new_owner; 
  }
}
