pragma solidity ^0.4.17;


import "./interfaces/TokenToTokenSwap_Interface.sol";
import "./interfaces/Factory_Interface.sol";
import "./Wrapped_Ether.sol";
import "./libraries/SafeMath.sol";

//The User Contract enables the entering of a deployed swap along with the wrapping of Ether.  This contract was specifically made for drct.decentralizedderivatives.org to simplify user metamask calls
contract UserContract{
  TokenToTokenSwap_Interface swap;
  Wrapped_Ether token;
  Factory_Interface factory;

  address public factory_address;
  address owner;

  function UserContract() public {
      owner = msg.sender;
  }

  //The _swapAdd is the address of the deployed contract created from the Factory contract.
  //_amounta and _amountb are the amounts of token_a and token_b (the base tokens) in the swap.  For wrapped Ether, this is wei.
  //_premium is a base payment to the other party for taking the other side of the swap
  // _isLong refers to whether the sender is long or short the reference rate
  //Value must be sent with Initiate and Enter equivalent to the _amounta(in wei) and the premium, and _amountb respectively

  function Initiate(address _swapadd, uint _amounta, uint _amountb, uint _premium, bool _isLong) payable public returns (bool) {
    require(msg.value == _amounta + _premium);
    swap = TokenToTokenSwap_Interface(_swapadd);
    swap.CreateSwap.value(_premium)(_amounta, _amountb, _isLong, msg.sender);
    address token_a_address;
    address token_b_address;
    (token_a_address,token_b_address) = factory.getBase();
    token = Wrapped_Ether(token_a_address);
    token.CreateToken.value(_amounta)();
    bool success = token.transfer(_swapadd,_amounta);
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
    token.CreateToken.value(_amountb)();
    bool success = token.transfer(_swapadd,_amountb);
    swap.createTokens();
    return success;

  }


  function setFactory(address _factory_address) public {
      require (msg.sender == owner);
    factory_address = _factory_address;
    factory = Factory_Interface(factory_address);
  }
}
