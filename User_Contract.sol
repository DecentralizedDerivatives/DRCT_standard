pragma solidity ^0.4.17;


import "./interfaces/TokenToTokenSwap_Interface.sol";
import "./interfaces/Factory.sol";
import "./WrappedEther.sol";
import "./libraries/SafeMath.sol";



contract UserContract{
  TokenToTokenSwap_Interface swap;
  Wrapped_Ether token;
  Factory_Interface factory;

  address public factory_address;

  function Initiate(uint _amounta, uint _amountb, uint _premium, bool _isLong) payable public returns (address) {
    require(msg.value == _amounta);
    address swap_contract = factory.deployContract(msg.sender);
    swap = TokenToTokenSwap_Interface(swap_contract);
    swap.CreateSwap.value(_premium)(_amounta, _amountb, _isLong);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_a_address);
    token.CreateToken.value(msg.value)();
    token.transfer(swap_contract,msg.value);
    return swap_contract;
  }

  function Enter(uint _amounta, uint _amountb, bool _isLong, address _swapadd) payable public {
    require(msg.value ==_amountb);
    swap = TokenToTokenSwap_Interface(_swapadd);
    swap.EnterSwap(_amounta, _amountb, _isLong);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_b_address);
    token.CreateToken.value(msg.value)();
    token.transfer(_swapadd,msg.value);
    swap.createTokens();
  }

  function setFactory(address _factory_address) public {
    factory_address = _factory_address;
    factory = Factory_Interface(factory_address);
  }
}
