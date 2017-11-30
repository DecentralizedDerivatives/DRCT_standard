pragma solidity ^0.4.17;

import "./TokenToTokenSwap.sol";
import "./DRCT_Interface.sol";


contract Factory {
     using SafeMath for uint256;
  /*Variables*/
  //Addresses of the Factory owner and oracle. For oracle information, check www.github.com/DecentralizedDerivatives/Oracles
  address public owner;
  address public oracle_address;
  DRCT_Interface drctint;

  address public long_drct;
  address public short_drct;
  address public token_a;
  address public token_b;

  //Swap creation amount in wei
  uint public fee;
  uint public duration;
  uint public multiplier;
  uint public tokenratio1;
  uint public tokenratio2;
  uint public start_date;


  //Array of deployed contracts
  address[] public contracts;
  mapping(address => bool) public created_contracts;

  /*Events*/

  //Emitted when a Swap is created
  event ContractCreation(address _created);

  /*Modifiers*/

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /*Functions*/

  /*
  * Constructor - Sets owner and fee amount
  *
  * @param "_fee": The contract creation fee, in finney
  * @param "_o_address": The oracle address
  */
  function Factory() public {
    owner = msg.sender;
  }

  /*
  * Updates the fee amount, and emits a FeeChange event
  *
  * @param "_fee": The new fee amount in finney
  */
  function setFee(uint _fee) public onlyOwner() {
    fee = _fee;
  }

  function settokens(address _longdrct, address _shortdrct) public onlyOwner() {
    long_drct = _longdrct;
    short_drct = _shortdrct;

    }

  function setStartDate(uint _start_date) public onlyOwner() {
        start_date = _start_date;
  }

//10e15,10e15,7,2,"0x..","0x..."
  function setVariables(uint _token_ratio1, uint _token_ratio2, uint _duration, uint _multiplier) public onlyOwner() {
    tokenratio1 = _token_ratio1;
    tokenratio2 = _token_ratio2;
    duration = _duration;
    multiplier = _multiplier;

  }
  
  function setBaseTokens(address _token_a, address _token_b)public onlyOwner() {
    token_a = _token_a;
    token_b = _token_b; 
  }
  //Allows a user to deploy a TokenToTokenSwap contract
  function deployContract() public payable returns (address created) {
    require(msg.value >= fee);
    address new_contract = new TokenToTokenSwap(address(this),msg.sender);
    contracts.push(new_contract);
    created_contracts[new_contract] = true;
    return new_contract;
  }

  /*
  * Deploys a DRCT_Token contract, sent from the swap contract
  TODO optional: have a mapping of address -> bool that allows us to restrict this function to swap contracts only
  */
  function createToken(uint _supply, address _party, bool long) public returns (address created, uint tokenratio) {
    require (created_contracts[msg.sender] == true);
    if (long){
      drctint = DRCT_Interface(long_drct);
      drctint.createToken(_supply.div(tokenratio1),_party);
          return (long_drct,tokenratio1);
    }
    else{
      drctint = DRCT_Interface(short_drct);
      drctint.createToken(_supply.div(tokenratio2),_party);
          return (short_drct,tokenratio2);
    }

  }

  //Allows the owner to set a new oracle address
  function setOracleAddress(address _new_oracle_address) public onlyOwner() { oracle_address = _new_oracle_address; }

  //Allows the owner to set a new owner address
  function setOwner(address _new_owner) public onlyOwner() { owner = _new_owner; }

  //Allows the owner to pull contract creation fees
  function withdrawFees() public onlyOwner() { owner.transfer(this.balance); }


  function getVariables() public returns(address _oracle_address,address _operator,uint _duration,uint _multiplier,address _token_a_address,address _token_b_address,uint _start_date){
    return (oracle_address,owner,duration,multiplier,token_a,token_b,start_date);
  }

  function payToken(address _party, bool long) public{
    require (created_contracts[msg.sender] == true);
    if (long){
      drctint = DRCT_Interface(long_drct);
    }
    else{
      drctint = DRCT_Interface(short_drct);
    }
    drctint.pay(_party);
  }
}
