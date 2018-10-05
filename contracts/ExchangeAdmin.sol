import "ITokenLedger.sol";

//tokenLedger=Exchange
//itokenLeder=exchange interfac
//organization= 
//storage=

//https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88
//
contract ExchangeAdmin {
  ITokenLedger public tokenLedger;

  function ExchangeAdmin(address _tokenLedger) {
    tokenLedger = ITokenLedger(_tokenLedger);
  }
  
  function setTokenLedgerAddress(address _tokenLedger)  {
    tokenLedger = ITokenLedger(_tokenLedger);
  }

  function generateTokens(uint256 _amount)  {
    tokenLedger.generateTokens(_amount);
  }
}