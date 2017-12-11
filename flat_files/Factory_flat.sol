pragma solidity ^0.4.17;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

//ERC20 function interface
interface ERC20_Interface {
  function totalSupply() public constant returns (uint total_supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
  function approve(address _spender, uint _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint amount);
}

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _owner, bool long) public returns (address created, uint tokenratio);
  function payToken(address _party, bool long) public;
   function deployContract(address swap_owner) public payable returns (address created);
   function getBase() public view returns(address _base1, address base2);
  function getVariables() public view returns (address oracle_addr, address factory_operator, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr, uint swap_start_date);
}


//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount(address _swap) public constant returns (uint count);
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder);
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal);
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index);
  function createToken(uint _supply, address _owner, address _swap) public;
  function pay(address _party, address _swap) public;
  function partyCount(address _swap) public constant returns(uint count);
}

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function RetrieveData(uint _date) public constant returns (uint data);
}

//Swap Deployer functions - descriptions can be found in Deployer.sol
interface Deployer_Interface {
  function newContract(address _party, address user_contract) public payable returns (address created);
}

//The Factory contract sets the standardized variables and also deploys new contracts based on these variables for the user.  
contract Factory {
  using SafeMath for uint256;
  //Addresses of the Factory owner and oracle. For oracle information, check www.github.com/DecentralizedDerivatives/Oracles
  address public owner;
  address public oracle_address;

  //Address of the user contract
  address public user_contract;
  DRCT_Token_Interface drct_interface;

  //Address of the deployer contract
  address deployer_address;
  Deployer_Interface deployer;

  address public long_drct;
  address public short_drct;
  address public token_a;
  address public token_b;

  //A fee for creating a swap in wei.  Plan is for this to be zero, however can be raised to prevent spam
  uint public fee;
  //Duration of swap contract in days
  uint public duration;
  //Multiplier of reference rate.  2x refers to a 50% move generating a 100% move in the contract payout values
  uint public multiplier;
  //Token_ratio refers to the number of DRCT Tokens a party will get based on the number of base tokens.  As an example, 1e15 indicates that a party will get 1000 DRCT Tokens based upon 1 ether of wrapped wei. 
  uint public token_ratio1;
  uint public token_ratio2;
  //Unix timestamp for the start date of the contract.  The end date is the start date + duration and the capped value is the value at the start date +- (start value/ multiplier)
  uint public start_date;


  //Array of deployed contracts
  address[] public contracts;
  mapping(address => bool) public created_contracts;

  //Emitted when a Swap is created
  event ContractCreation(address _sender, address _created);

  /*Modifiers*/
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /*Functions*/
  // Constructor - Sets owner
  function Factory() public {
    owner = msg.sender;
  }

  /*
  * Updates the fee amount
  * @param "_fee": The new fee amount
  */
  function setFee(uint _fee) public onlyOwner() {
    fee = _fee;
  }

  /*
  * Sets the deployer address
  * @param "_deployer": The new deployer address
  */
  function setDeployer(address _deployer) public onlyOwner() {
    deployer_address = _deployer;
    deployer = Deployer_Interface(_deployer);
  }
  /*
  * Sets the user_contract address
  * @param "_userContract": The new userContract address
  */
  function setUserContract(address _userContract) public onlyOwner() {
    user_contract = _userContract;
  }

  /*
  * A getter to retrieve the base tokens
  */
  function getBase() public view returns(address _base1, address base2){
    return (token_a, token_b);
  }

  /*
  * Sets the long and short DRCT token addresses
  * @param "_long_drct": The address of the long DRCT token
  * @param "_short_drct": The address of the short DRCT token
  */
  function settokens(address _long_drct, address _short_drct) public onlyOwner() {
    long_drct = _long_drct;
    short_drct = _short_drct;
  }

  /*
  * Sets the start date of a swap
  * @param "_start_date": The new start date
  */
  function setStartDate(uint _start_date) public onlyOwner() {
    start_date = _start_date;
  }

  /*
  * Sets token ratio, swap duration, and multiplier variables for a swap
  * @param "_token_ratio1": The ratio of the first token
  * @param "_token_ratio2": The ratio of the second token
  * @param "_duration": The duration of the swap, in seconds
  * @param "_multiplier": The multiplier used for the swap
  */
  //10e15,10e15,7,2,"0x..","0x..."
  function setVariables(uint _token_ratio1, uint _token_ratio2, uint _duration, uint _multiplier) public onlyOwner() {
    token_ratio1 = _token_ratio1;
    token_ratio2 = _token_ratio2;
    duration = _duration;
    multiplier = _multiplier;
  }

  /*
  * Sets the addresses of the tokens used for the swap
  * @param "_token_a": The address of a token to be used
  * @param "_token_b": The address of another token to be used
  */
  function setBaseTokens(address _token_a, address _token_b) public onlyOwner() {
    token_a = _token_a;
    token_b = _token_b;
  }

  //Allows a user to deploy a new swap contract, if they pay the fee
  //returns the newly created swap address and calls event 'ContractCreation'
  function deployContract() public payable returns (address created) {
    require(msg.value >= fee);
    address new_contract = deployer.newContract(msg.sender, user_contract);
    contracts.push(new_contract);
    created_contracts[new_contract] = true;
    ContractCreation(msg.sender,new_contract);
    return new_contract;
  }

  /*
  * Deploys a DRCT_Token contract, sent from an already-deployed swap contract
  * @param "_supply": The number of tokens to create
  * @param "_party": The address to send the tokens to
  * @param "_long": Whether the party is long or short
  * @returns "created": The address of the created DRCT token
  * @returns "token_ratio": The ratio of the created DRCT token
  */
  function createToken(uint _supply, address _party, bool _long) public returns (address created, uint token_ratio) {
    require(created_contracts[msg.sender] == true);
    if (_long) {
      drct_interface = DRCT_Token_Interface(long_drct);
      drct_interface.createToken(_supply.div(token_ratio1), _party,msg.sender);
      return (long_drct, token_ratio1);
    } else {
      drct_interface = DRCT_Token_Interface(short_drct);
      drct_interface.createToken(_supply.div(token_ratio2), _party,msg.sender);
      return (short_drct, token_ratio2);
    }
  }
  

  //Allows the owner to set a new oracle address
  function setOracleAddress(address _new_oracle_address) public onlyOwner() { oracle_address = _new_oracle_address; }

  //Allows the owner to set a new owner address
  function setOwner(address _new_owner) public onlyOwner() { owner = _new_owner; }

  //Allows the owner to pull contract creation fees
  function withdrawFees() public onlyOwner() { owner.transfer(this.balance); }

  /*
  * Returns a tuple of many private variables
  * @returns "_oracle_adress": The address of the oracle
  * @returns "_operator": The address of the owner and operator of the factory
  * @returns "_duration": The duration of the swap
  * @returns "_multiplier": The multiplier for the swap
  * @returns "token_a_address": The address of token a
  * @returns "token_b_address": The address of token b
  * @returns "start_date": The start date of the swap
  */
  function getVariables() public view returns (address oracle_addr, address operator, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr, uint swap_start_date){
    return (oracle_address, owner, duration, multiplier, token_a, token_b, start_date);
  }

  /*
  * Pays out to a DRCT token
  * @param "_party": The address being paid
  * @param "_long": Whether the _party is long or not
  */
  function payToken(address _party, bool _long) public {
    require(created_contracts[msg.sender] == true);
    if (_long) {
      drct_interface = DRCT_Token_Interface(long_drct);
    } else {
      drct_interface = DRCT_Token_Interface(short_drct);
    }
    drct_interface.pay(_party, msg.sender);
  }

  //Returns the number of contracts created by this factory
    function getCount() public constant returns(uint count) {
      return contracts.length;
  }
}
