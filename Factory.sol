pragma solidity ^0.4.17;

import "./interfaces/Deployer_Interface.sol";
import "./interfaces/DRCT_Token_Interface.sol";
import "./libraries/SafeMath.sol";


contract Factory {
  using SafeMath for uint256;
  /*Variables*/

  //Addresses of the Factory owner and oracle. For oracle information, check www.github.com/DecentralizedDerivatives/Oracles
  address public owner;
  address public oracle_address;
  DRCT_Token_Interface drct_interface;

  //Address of the deployer contract
  address deployer_address;
  Deployer_Interface deployer;

  address public long_drct;
  address public short_drct;
  address public token_a;
  address public token_b;

  //Swap creation amount in wei
  uint public fee;
  uint public duration;
  uint public multiplier;
  uint public token_ratio1;
  uint public token_ratio2;
  uint public start_date;


  //Array of deployed contracts
  address[] public contracts;
  mapping(address => bool) public created_contracts;

  /*Events*/

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
  function deployContract() public payable returns (address created) {
    require(msg.value >= fee);
    address new_contract = deployer.newContract(msg.sender);
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
      drct_interface.createToken(_supply.div(token_ratio1), _party);
      return (long_drct, token_ratio1);
    } else {
      drct_interface = DRCT_Token_Interface(short_drct);
      drct_interface.createToken(_supply.div(token_ratio2), _party);
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
    //TODO why is this being changed every call
    if (_long) {
      drct_interface = DRCT_Token_Interface(long_drct);
    } else {
      drct_interface = DRCT_Token_Interface(short_drct);
    }
    drct_interface.pay(_party);
  }
}
