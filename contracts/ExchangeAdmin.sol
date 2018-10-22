pragma solidity ^0.4.24;

//https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88
//
/* import "Exchange_Interface.sol";   
   
  contract Organisation
  {
    Exchange_Interface public exchange;
    Address exchangeStorage;
    address public owner; 
   
    /*Modifiers*/
    /**
    *@dev Access modifier for Owner functionality
    */
/*     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    } */

    /**
    *@dev the constructor argument to set the owner and initialize the array.
    */
/*     constructor() public{
        owner = msg.sender;
    }
    function changeExchangeStorageAddress(address _exchangeStorage) onlyOwner public{
      exchangeStorage = _exchangeStorage;
    }
    
    function setExchangeAddress(address _exchange) onlyOwner public {
      exchange = Exchange_Interface(_exchange);
    }
   
  }  */
