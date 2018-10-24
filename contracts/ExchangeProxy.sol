pragma solidity ^0.4.24;

import "./ExchangeStorage.sol";

contract ExchangeProxy{
    
  ExchangeStorage _storage;

  address public owner;
    modifier onlyOwner() {
        require(msg.sender == _storage.getOwner());
        _;
    }
   
  constructor(ExchangeStorage storage_ , address _owner) public {
    _storage = storage_;
    _storage.setOwner(_owner);
  }

  event Upgraded(address indexed implementation);

  address public _implementation;

  function implementation() public view returns (address) {
    return _implementation;
  }

  function upgradeTo(address impl) public onlyOwner {
    require(_implementation != impl);
    _implementation = impl;
    emit Upgraded(impl);
  }
 
  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

}