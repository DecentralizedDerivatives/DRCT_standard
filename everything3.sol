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

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _owner, bool long) public returns (address created, uint tokenratio);
  function payToken(address _party, bool long) public;
   function deployContract(address swap_owner) public payable returns (address created);
   function getBase() public view returns(address _base1, address base2);
  function getVariables() public view returns (address oracle_addr, address factory_operator, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr, uint swap_start_date);
}

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function RetrieveData(uint _date) public view returns (uint data);
}

//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount(address _swap) public constant returns (uint count);
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder);
  /*function getDeepHolderByIndex(uint _ind, address _swap) public constant returns (address holder);*/

  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal);

  /*function getBalanceByIndex(uint _ind) public constant returns (uint bal);*/
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index);
  function createToken(uint _supply, address _owner, address _swap) public;
  function pay(address _party, address _swap) public;
  function partyCount(address _swap) public constant returns(uint count);
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

//Swap Deployer Contract
contract Deployer {
  address owner;

  function Deployer(address _factory) public {
    owner = _factory;
  }

  //TODO - payable?
  function newContract(address _party, address user_contract) public returns (address created) {
    require(msg.sender == owner);
    address new_contract = new TokenToTokenSwap(owner, _party, user_contract);
    return new_contract;
  }
}

//Swap Deployer functions - descriptions can be found in Deployer.sol
interface Deployer_Interface {
  function newContract(address _party, address user_contract) public payable returns (address created);
}

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface TokenToTokenSwap_Interface {
  function CreateSwap(uint _amount_a, uint _amount_b, bool _sender_is_long, address _senderAdd) public payable;
  function EnterSwap(uint _amount_a, uint _amount_b, bool _sender_is_long, address _senderAdd) public;
  function createTokens() public;
}

contract UserContract{
  TokenToTokenSwap_Interface swap;
  Wrapped_Ether token;
  Factory_Interface factory;

  address public factory_address;
  address owner;

  function UserContract() public {
      owner = msg.sender;
  }

  function Initiate(address _swapadd, uint _amounta, uint _amountb, uint _premium, bool _isLong) payable public returns (bool) {
    require(msg.value == _amounta + _premium);
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
}

contract Factory {
  using SafeMath for uint256;
  /*Variables*/

  //Addresses of the Factory owner and oracle. For oracle information, check www.github.com/DecentralizedDerivatives/Oracles
  address public owner;
  address public oracle_address;
  address public user_contract;
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

    function setUserContract(address _userContract) public onlyOwner() {
    user_contract = _userContract;
  }


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
    //TODO why is this being changed every call
    if (_long) {
      drct_interface = DRCT_Token_Interface(long_drct);
    } else {
      drct_interface = DRCT_Token_Interface(short_drct);
    }
    drct_interface.pay(_party, msg.sender);
  }

  function getCount() public constant returns(uint count) {
    return contracts.length;
}
}

contract Oracle {

  /*Variables*/

  //Owner of the oracle
  address private owner;

  //Mapping of documents stored in the oracle
  mapping(uint => uint) oracle_values;

  /*Events*/

  event DocumentStored(uint _key, uint _value);

  /*Functions*/

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  //Constructor - Sets owner
  function Oracle() public {
    owner = msg.sender;
  }

  //Allows the owner of the Oracle to store a document in the oracle_values mapping. Documents
  //represent underlying values at a specified date (key).
  function StoreDocument(uint _key, uint _value) public onlyOwner() {
    oracle_values[_key] = _value;
    DocumentStored(_key, _value);
  }

  //Allows for the viewing of oracle data
  function RetrieveData(uint _date) public constant returns (uint data) {
    return oracle_values[_date];
  }
  function setOwner(address _new_owner) public onlyOwner() { owner = _new_owner; }
}

contract DRCT_Token {

  using SafeMath for uint256;

  /*Structs */

  //Keeps track of balance amounts in the balances array
  struct Balance {
    address owner;
    uint amount;
  }

  address public master_contract;

  uint public total_supply;

  //Mapping from: swap address -> user balance struct (index for a particular user's balance can be found in swap_balances_index)
  mapping(address => Balance[]) swap_balances;
  //Mapping from: swap address -> user -> swap_balances index
  mapping(address => mapping(address => uint)) swap_balances_index;
  //Mapping from: user -> dynamic array of swap addresses (index for a particular swap can be found in user_swaps_index)
  mapping(address => address[]) user_swaps;
  //Mapping from: user -> swap address -> user_swaps index
  mapping(address => mapping(address => uint)) user_swaps_index;

  //Mapping from: user -> total balance accross all entered swaps
  mapping(address => uint) user_total_balances;
  //Mapping from: owner -> spender -> amount allowed
  mapping(address => mapping(address => uint)) allowed;

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  modifier onlyMaster() {
    require(msg.sender == master_contract);
    _;
  }

  /*Functions*/

  //Constructor
  function DRCT_Token(address _factory) public {
    //Sets values for token name and token supply, as well as the master_contract, the swap.
    master_contract = _factory;
  }

  //TODO - description
  function createTokenTest(uint _supply, address _owner, address _swap) public onlyMaster() {
    //Update total supply of DRCT Tokens
    total_supply = total_supply.add(_supply);
    //Update the total balance of the owner
    user_total_balances[_owner] = user_total_balances[_owner].add(_supply);
    //If the user has not entered any swaps already, push a zeroed address to their user_swaps mapping to prevent default value conflicts in user_swaps_index
    if (user_swaps[_owner].length == 0)
      user_swaps[_owner].push(address(0x0));
    //Add a new swap index for the owner
    user_swaps_index[_owner][_swap] = user_swaps[_owner].length;
    //Push a new swap address to the owner's swaps
    user_swaps[_owner].push(_swap);
    //Push a zeroed Balance struct to the swap balances mapping to prevent default value conflicts in swap_balances_index
    swap_balances[_swap].push(Balance({
      owner: 0,
      amount: 0
    }));
    //Add a new owner balance index for the swap
    swap_balances_index[_swap][_owner] = 1;
    //Push the owner's balance to the swap
    swap_balances[_swap].push(Balance({
      owner: _owner,
      amount: _supply
    }));
  }

  //Called by the factory contract, and pays out to a _party
  function pay(address _party, address _swap) public onlyMaster() {
    uint party_balance_index = swap_balances_index[_swap][_party];
    uint party_swap_balance = swap_balances[_swap][party_balance_index].amount;

    user_total_balances[_party] = user_total_balances[_party].sub(party_swap_balance);
    total_supply = total_supply.sub(party_swap_balance);
    //Remove party from swap balances
    removeFromSwapBalances(_party, _swap);
    //Remove swap from party swap list
    removeFromUserSwaps(_party, _swap);
  }

  //TODO - description
  function balanceOf(address _owner) public constant returns (uint balance) { return user_total_balances[_owner]; }

  //TODO - description
  function totalSupply() public constant returns (uint _total_supply) { return total_supply; }

  //Checks whether an address is in a specified swap. If they are, the user_swaps_index for that user and swap will be non-zero
  function addressInSwap(address _swap, address _owner) public view returns (bool) {
    return user_swaps_index[_owner][_swap] != 0;
  }

  //TODO - description
  function removeFromUserSwaps(address _user, address _swap) internal {
    uint last_address_index = user_swaps[_user].length.sub(1);
    address last_address = user_swaps[_user][last_address_index];
    if (last_address != _swap) {
      uint remove_index = user_swaps_index[_user][_swap];
      user_swaps_index[_user][last_address] = remove_index;
      user_swaps[_user][remove_index] = user_swaps[_user][last_address_index];
    }
    delete user_swaps_index[_user][_swap];
    user_swaps[_user].length = user_swaps[_user].length.sub(1);
  }

  //Removes the address from the swap balances for a swap, and moves the last address in the swap into their place
  function removeFromSwapBalances(address _remove, address _swap) internal {
    uint last_address_index = swap_balances[_swap].length.sub(1);
    address last_address = swap_balances[_swap][last_address_index].owner;
    //If the address we want to remove is the final address in the swap
    if (last_address != _remove) {
      uint remove_index = swap_balances_index[_swap][_remove];
      //Update the swap's balance index of the last address to that of the removed address index
      swap_balances_index[_swap][last_address] = remove_index;
      //Set the swap's Balance struct at the removed index to the Balance struct of the last address
      swap_balances[_swap][remove_index] = swap_balances[_swap][last_address_index];
    }
    //Remove the swap_balances index for this address
    delete swap_balances_index[_swap][_remove];
    //Finally, decrement the swap balances length
    swap_balances[_swap].length = swap_balances[_swap].length.sub(1);
  }

  //TODO - description
  //TODO - split this function into helpers
  function transferHelper(address _from, address _to, uint _amount) internal {
    //Get memory copies of the swap arrays for the sender and reciever
    address[] memory from_swaps = user_swaps[_from];

    //Iterate over sender's swaps in reverse order until enough tokens have been transferred
    for (uint i = from_swaps.length.sub(1); i > 0; i--) {
      //Get the index of the sender's balance for the current swap
      uint from_swap_user_index = swap_balances_index[from_swaps[i]][_from];
      Balance memory from_user_bal = swap_balances[from_swaps[i]][from_swap_user_index];
      //If the current swap will be entirely depleted - we remove all references to it for the sender
      if (_amount >= from_user_bal.amount) {
        _amount -= from_user_bal.amount;
        //If this swap is to be removed, we know it is the (current) last swap in the user's user_swaps list, so we can simply decrement the length to remove it
        user_swaps[_from].length = user_swaps[_from].length.sub(1);
        //Remove the user swap index for this swap
        delete user_swaps_index[_from][from_swaps[i]];

        //If the _to address already holds tokens from this swap
        if (addressInSwap(from_swaps[i], _to)) {
          //Get the index of the _to balance in this swap
          uint to_balance_index = swap_balances_index[from_swaps[i]][_to];
          assert(to_balance_index != 0);
          //Add the _from tokens to _to
          swap_balances[from_swaps[i]][to_balance_index].amount = swap_balances[from_swaps[i]][to_balance_index].amount.add(from_user_bal.amount);
          //Remove the _from address from this swap's balance array
          removeFromSwapBalances(_from, from_swaps[i]);
        } else {
          //Prepare to add a new swap by assigning the swap an index for _to
          if (user_swaps[_to].length == 0)
            user_swaps_index[_to][from_swaps[i]] = 1;
          else
            user_swaps_index[_to][from_swaps[i]] = user_swaps[_to].length;
          //Add the new swap to _to
          user_swaps[_to].push(from_swaps[i]);
          //Give the reciever the sender's balance for this swap
          swap_balances[from_swaps[i]][from_swap_user_index].owner = _to;
          //Give the reciever the sender's swap balance index for this swap
          swap_balances_index[from_swaps[i]][_to] = swap_balances_index[from_swaps[i]][_from];
          //Remove the swap balance index from the sending party
          delete swap_balances_index[from_swaps[i]][_from];
        }
        //If there is no more remaining to be removed, we break out of the loop
        if (_amount == 0)
          break;
      } else {
        //The amount in this swap is more than the amount we still need to transfer
        uint to_swap_balance_index = swap_balances_index[from_swaps[i]][_to];
        //If the _to address already holds tokens from this swap
        if (addressInSwap(from_swaps[i], _to)) {
          //Because both addresses are in this swap, and neither will be removed, we simply update both swap balances
          swap_balances[from_swaps[i]][to_swap_balance_index].amount = swap_balances[from_swaps[i]][to_swap_balance_index].amount.add(_amount);
        } else {
          //Prepare to add a new swap by assigning the swap an index for _to
          if (user_swaps[_to].length == 0)
            user_swaps_index[_to][from_swaps[i]] = 1;
          else
            user_swaps_index[_to][from_swaps[i]] = user_swaps[_to].length;
          //And push the new swap
          user_swaps[_to].push(from_swaps[i]);
          //_to is not in this swap, so we give this swap a new balance index for _to
          swap_balances_index[from_swaps[i]][_to] = swap_balances[from_swaps[i]].length;
          //And push a new balance for _to
          swap_balances[from_swaps[i]].push(Balance({
            owner: _to,
            amount: _amount
          }));
        }
        //Finally, update the _from user's swap balance
        swap_balances[from_swaps[i]][from_swap_user_index].amount = swap_balances[from_swaps[i]][from_swap_user_index].amount.sub(_amount);
        //Because we have transferred the last of the amount to the reciever, we break;
        break;
      }
    }
  }

  //TODO - description
  function transfer(address _to, uint _amount) public returns (bool success) {
    uint balance_owner = user_total_balances[msg.sender];

    if (
      _to == msg.sender ||
      _to == address(0) ||
      _amount == 0 ||
      balance_owner < _amount
    ) return false;

    transferHelper(msg.sender, _to, _amount);
    user_total_balances[msg.sender] = user_total_balances[msg.sender].sub(_amount);
    user_total_balances[_to] = user_total_balances[_to].add(_amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  //TODO - description
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    uint balance_owner = user_total_balances[_from];
    uint sender_allowed = allowed[_from][msg.sender];

    if (
      _to == _from ||
      _to == address(0) ||
      _amount == 0 ||
      balance_owner < _amount ||
      sender_allowed < _amount
    ) return false;

    transferHelper(_from, _to, _amount);
    user_total_balances[_from] = user_total_balances[_from].sub(_amount);
    user_total_balances[_to] = user_total_balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    Transfer(_from, _to, _amount);
    return true;
  }

  //TODO - description
  function approve(address _spender, uint _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  //Returns the length of the balances array for a swap
  function addressCount(address _swap) public constant returns (uint count) { return swap_balances[_swap].length; }

  //Returns the address associated with a particular index in a particular swap
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder) { return swap_balances[_swap][_ind].owner; }

  //Returns the balance associated with a particular index in a particular swap
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal) { return swap_balances[_swap][_ind].amount; }

  //Returns the index associated with the _owner address in a particular swap
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index) { return swap_balances_index[_swap][_owner]; }

  //Returns the allowed amount _spender can spend of _owner's balance
  function allowance(address _owner, address _spender) public constant returns (uint amount) { return allowed[_owner][_spender]; }
}

contract TokenToTokenSwap {

  using SafeMath for uint256;

  /*Enums*/

  //Describes various states of the Swap
  enum SwapState {
    created,
    open,
    started,
    tokenized,
    ready,
    ended
  }

  /*Variables*/

  //Address of the person who created this contract through the Factory
  address creator;

  //Address of an operator who will ensure forcePay is called at the end of the swap period
  address operator;

  //The Oracle address (check for list at www.github.com/DecentralizedDerivatives/Oracles)
  address oracle_address;
  Oracle_Interface oracle;

  //Address of the Factory that created this contract
  address public factory_address;
  Factory_Interface factory;

  //Addresses of parties going short and long the rate
  address public long_party;
  address public short_party;

  //Enum state of the swap
  SwapState public current_state;

  //Start and end dates of the swaps - format is the same as block.timestamp
  uint start_date;
  uint end_date;

  //This is the amount that the change will be calculated on.  10% change in rate on 100 Ether notional is a 10 Ether change
  uint multiplier;

  uint share_long;
  uint share_short;

  /*TODO description*/
  uint pay_to_short_a;
  uint pay_to_long_a;
  uint pay_to_long_b;
  uint pay_to_short_b;

  //Address of created long and short DRCT tokens
  address long_token_address;
  address short_token_address;

  //Number of DRCT Tokens distributed to both parties
  uint num_DRCT_longtokens;
  uint num_DRCT_shorttokens;

  //Addresses of ERC20 tokens used to enter the swap
  address token_a_address;
  address token_b_address;

  //Tokens A and B used for the notional
  ERC20_Interface token_a;
  ERC20_Interface token_b;

  //The notional that the payment is calculated on from the change in the reference rate
  uint public token_a_amount;
  uint public token_b_amount;

  uint public premium;

  //Addresses of the two parties taking part in the swap
  address token_a_party;
  address token_b_party;

  uint duration;
  uint fee;
  DRCT_Token_Interface token;
  address userContract;

  /*Events*/

  //Emitted when a Swap is created
  event SwapCreation(address _token_a, address _token_b, uint _start_date, uint _end_date, address _creating_party);
  //Emitted when the swap has been paid out
  event PaidOut(address _long_token, address _short_token);

  /*Modifiers*/

  //Will proceed only if the contract is in the expected state
  modifier onlyState(SwapState expected_state) {
    require(expected_state == current_state);
    _;
  }

  /*Functions*/

  /*
  * Constructor - Run by the factory at contract creation
  *
  * @param "_o_address": Oracle address
  * @param "_operator": Address of the operator
  * @param "_creator": Address of the person who created the contract
  * @param "_factory": Address of the factory that created this contract
  */
  function TokenToTokenSwap (address _factory_address, address _creator, address _userContract) public {
    current_state = SwapState.created;
    creator =_creator;
    factory_address = _factory_address;
    userContract = _userContract;
  }

  function showPrivateVars() public view returns (address _userContract, uint num_DRCT_long, uint numb_DRCT_short, uint swap_share_long, uint swap_share_short, address long_token_addr, address short_token_addr, address oracle_addr, address token_a_addr, address token_b_addr, uint swap_multiplier, uint swap_duration, uint swap_start_date, uint swap_end_date){
    return (userContract, num_DRCT_longtokens, num_DRCT_shorttokens,share_long,share_short,long_token_address,short_token_address, oracle_address, token_a_address, token_b_address, multiplier, duration, start_date, end_date);
  }

  /*
  * Allows the sender to create the terms for the swap
  *
  * @param "token_a_address": Address of ERC20 token A used as notional
  * @param "token_b_address": Address of ERC20 token B used as notional
  * @param "_amount_a": Amount of Token A that should be deposited for the notional
  * @param "_amount_b": Amount of Token B that should be deposited for the notional
  * @param "_multiplier": Integer multiplier representing amount of leverage on the underlying reference rate
  * @param "_start_date": Start date of the swap. Should be after the current block.timestamp
  * @param "_end_date": End date of the swap. Should be after the start date of the swap and no more than 28 days after the start date
  * @param "_sender_is_long": Denotes whether the sender is set as the short or long party
  */
  function CreateSwap(
    uint _amount_a,
    uint _amount_b,
    bool _sender_is_long,
    address _senderAdd
    ) payable public onlyState(SwapState.created) {

    //The Swap is meant to take place within 28 days
    require(
      msg.sender == creator || (msg.sender == userContract && _senderAdd == creator)
    );
    factory = Factory_Interface(factory_address);
    setVars();
    end_date = start_date.add(duration.mul(86400));
    token_a_amount = _amount_a;
    token_b_amount = _amount_b;

    premium = this.balance;
    token_a = ERC20_Interface(token_a_address);
    token_a_party = _senderAdd;
    if (_sender_is_long)
      long_party = _senderAdd;
    else
      short_party = _senderAdd;
    current_state = SwapState.open;
  }

  function setVars() internal{
      (oracle_address,operator,duration,multiplier,token_a_address,token_b_address,start_date) = factory.getVariables();
  }

  /*
  * This function is for those entering the swap. The details of the swap are re-entered and checked
  * to ensure the entering party is entering the correct swap. Note that the tokens you are entering with
  * do not need to be entered as a variable, but you should ensure that the contract is funded.
  *
  * @param: all parameters have the same functions as those in the CreateSwap function
  */
  function EnterSwap(
    uint _amount_a,
    uint _amount_b,
    bool _sender_is_long,
    address _senderAdd
    ) public onlyState(SwapState.open) {

    //Require that all of the information of the swap was entered correctly by the entering party
    require(
      token_a_amount == _amount_a &&
      token_b_amount == _amount_b &&
      token_a_party != _senderAdd
    );

    token_b = ERC20_Interface(token_b_address);
    token_b_party = _senderAdd;

    //Set the entering party as the short or long party
    if (_sender_is_long) {
      require(long_party == 0);
      long_party = _senderAdd;
    } else {
      require(short_party == 0);
      short_party = _senderAdd;
    }

    SwapCreation(token_a_address, token_b_address, start_date, end_date, token_b_party);
    current_state = SwapState.started;
  }

  /*
  * This function creates the DRCT tokens for the short and long parties, and ensures the short and long parties
  * have funded the contract with the correct amount of the ERC20 tokens A and B
  *
  * @param: "_tokens": Amount of DRCT Tokens to be created
  */
  function createTokens() public onlyState(SwapState.started){

    //Ensure the contract has been funded by tokens a and b
    require(
      now <= start_date &&
      token_a.balanceOf(address(this)) >= token_a_amount &&
      token_b.balanceOf(address(this)) >= token_b_amount
    );

    tokenize(long_party);
    tokenize(short_party);
    current_state = SwapState.tokenized;
    if (premium > 0){
      if (creator == long_party){
      short_party.transfer(premium);
      }
      else {
        long_party.transfer(premium);
      }
    }
  }

  /*
  * Creates DRCT tokens equal to the passed in _total_supply which credits them all to the _creator
  *
  * @param "_total_supply": The number of DRCT tokens that will be created
  * @param "_creator": The creator of the DRCT tokens
  */
  function tokenize(address _creator) internal {
    //Uses the factory to deploy a DRCT Token contract, which we cast to the DRCT_Token_Interface
    uint tokenratio = 1;
    if (_creator == long_party) {
      (long_token_address,tokenratio) = factory.createToken(token_a_amount, _creator,true);
      num_DRCT_longtokens = token_a_amount.div(tokenratio);
    } else if (_creator == short_party) {
      (short_token_address,tokenratio) = factory.createToken(token_b_amount, _creator,false);
      num_DRCT_shorttokens = token_b_amount.div(tokenratio);
    }
  }

  /*
  * This function calculates the payout of the swap. It can be called after the Swap has been tokenized.
  * The value of the underlying cannot reach zero, but rather can only get within 0.001 * the precision
  * of the Oracle.
  */
  function Calculate() internal {
    //require(now >= end_date);
    oracle = Oracle_Interface(oracle_address);
    uint start_value = oracle.RetrieveData(start_date);
    uint end_value = oracle.RetrieveData(end_date);

    uint ratio;
    if (start_value > 0 && end_value > 0)
      ratio = (end_value).mul(100000).div(start_value);
    else if (end_value > 0)
      ratio = 10e10;
    else if (start_value > 0)
      ratio = 0;
    else
      ratio = 100000;

    if (ratio == 100000) {
      share_long = share_short = ratio;
    } else if (ratio > 100000) {
      share_long = ((ratio).sub(100000)).mul(multiplier).add(100000);
      if (share_long >= 200000)
        share_short = 0;
      else
        share_short = 200000-share_long;
    } else {
      share_short = SafeMath.sub(100000,ratio).mul(multiplier).add(100000);
       if (share_short >= 200000)
        share_long = 0;
      else
        share_long = 200000- share_short;
    }

    //Calculate the payouts to long and short parties based on the short and long shares
    calculatePayout();

    current_state = SwapState.ready;
  }

  /*
  * Calculates the amount paid to the short and long parties TODO
  */
  function calculatePayout() internal {
    uint ratio;
    token_a_amount = token_a_amount.mul(995).div(1000);
    token_b_amount = token_b_amount.mul(995).div(1000);
    //If ratio is flat just swap tokens, otherwise pay the winner the entire other token and only pay the other side a portion of the opposite token
    if (share_long == 100000) {
      pay_to_short_a = (token_a_amount).div(num_DRCT_longtokens);
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_b = 0;
      pay_to_long_a = 0;
    } else if (share_long > 100000) {
      ratio = SafeMath.min(100000, (share_long).sub(100000));
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_a = (SafeMath.sub(100000,ratio)).mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_long_a = ratio.mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_short_b = 0;
    } else {
      ratio = SafeMath.min(100000, (share_short).sub(100000));
      pay_to_short_a = (token_a_amount).div(num_DRCT_longtokens);
      pay_to_long_b = (SafeMath.sub(100000,ratio)).mul(token_b_amount).div(num_DRCT_shorttokens).div(100000);
      pay_to_short_b = ratio.mul(token_b_amount).div(num_DRCT_shorttokens).div(100000);
      pay_to_long_a = 0;
    }
  }

  /*
  * This function can be called after the swap is tokenized or after the Calculate function is called.
  * If the Calculate function has not yet been called, this function will call it.
  * The function then pays every token holder of both the long and short DRCT tokens
  */
  function forcePay(uint _begin, uint _end) public returns (bool) {
    //Calls the Calculate function first to calculate short and long shares
    if(current_state == SwapState.tokenized){
      Calculate();
    }

    //The state at this point should always be SwapState.ready
    require(msg.sender == operator && current_state == SwapState.ready);

    //Loop through the owners of long and short DRCT tokens and pay them

    token = DRCT_Token_Interface(long_token_address);
    uint count = token.addressCount(address(this));
    uint loop_count = count < _end ? count : _end;
    //Indexing begins at 1 for DRCT_Token balances
    for(uint i = _begin; i < loop_count; i++) {
      address long_owner = token.getHolderByIndex(i, address(this));
      uint to_pay_long = token.getBalanceByIndex(i, address(this));
      paySwap(long_owner, to_pay_long, true);
    }

    token = DRCT_Token_Interface(short_token_address);
    count = token.addressCount(address(this));
    loop_count = count < _end ? count : _end;
    for(uint j = _begin; j < loop_count; j++) {
      address short_owner = token.getHolderByIndex(j, address(this));
      uint to_pay_short = token.getBalanceByIndex(j, address(this));
      paySwap(short_owner, to_pay_short, false);
    }

    if (loop_count == count){
        token_a.transfer(operator, token_a.balanceOf(address(this)));
        token_b.transfer(operator, token_b.balanceOf(address(this)));
        PaidOut(long_token_address, short_token_address);
        current_state = SwapState.ended;
      }
    return true;
  }

  /*
  * This function pays the receiver an amount determined by the Calculate function
  *
  * @param "_receiver": The recipient of the payout
  * @param "_amount": The amount of token the recipient holds
  * @param "_is_long": Whether or not the reciever holds a long or short token
  */
  function paySwap(address _receiver, uint _amount, bool _is_long) internal {
    if (_is_long) {
      if (pay_to_long_a > 0)
        token_a.transfer(_receiver, _amount.mul(pay_to_long_a));
      if (pay_to_long_b > 0){
        token_b.transfer(_receiver, _amount.mul(pay_to_long_b));
      }
        factory.payToken(_receiver,true);
    } else {

      if (pay_to_short_a > 0)
        token_a.transfer(_receiver, _amount.mul(pay_to_short_a));
      if (pay_to_short_b > 0){
        token_b.transfer(_receiver, _amount.mul(pay_to_short_b));
      }
       factory.payToken(_receiver,false);
    }
  }


  /*
  * This function allows both parties to exit. If only the creator has entered the swap, then the swap can be cancelled and the details modified
  * Once two parties enter the swap, the contract is null after cancelled.
  */
  function Exit() public {
   if (current_state == SwapState.open && msg.sender == token_a_party) {
      token_a.transfer(token_a_party, token_a_amount);
      if (premium>0){
        msg.sender.transfer(premium);
      }
      delete token_a_amount;
      delete token_b_amount;
      delete premium;
      current_state = SwapState.created;
    } else if (current_state == SwapState.started && (msg.sender == token_a_party || msg.sender == token_b_party)) {
      if (msg.sender == token_a_party || msg.sender == token_b_party) {
        token_b.transfer(token_b_party, token_b.balanceOf(address(this)));
        token_a.transfer(token_a_party, token_a.balanceOf(address(this)));
        current_state = SwapState.ended;
        if (premium > 0) { creator.transfer(premium);}
      }
    }
  }
}

contract Wrapped_Ether {

  using SafeMath for uint256;

  /*Variables*/

  //ERC20 fields
  string public name = "Wrapped Ether";
  uint public total_supply;


  //ERC20 fields
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint)) allowed;

  /*Events*/

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event StateChanged(bool _success, string _message);

  /*Functions*/

  //This function creates tokens equal in value to the amount sent to the contract
  function CreateToken() public payable {
    require(msg.value > 0);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    total_supply = total_supply.add(msg.value);
  }

  /*
  * This function 'unwraps' an _amount of Ether in the sender's balance by transferring Ether to them
  *
  * @param "_amount": The amount of the token to unwrap
  */
  function withdraw(uint _value) public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    total_supply = total_supply.sub(_value);
    msg.sender.transfer(_value);
  }

  //Returns the balance associated with the passed in _owner
  function balanceOf(address _owner) public constant returns (uint bal) { return balances[_owner]; }

  /*
  * Allows for a transfer of tokens to _to
  *
  * @param "_to": The address to send tokens to
  * @param "_amount": The amount of tokens to send
  */
  function transfer(address _to, uint _amount) public returns (bool success) {
    if (balances[msg.sender] >= _amount
    && _amount > 0
    && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  /*
  * Allows an address with sufficient spending allowance to send tokens on the behalf of _from
  *
  * @param "_from": The address to send tokens from
  * @param "_to": The address to send tokens to
  * @param "_amount": The amount of tokens to send
  */
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    if (balances[_from] >= _amount
    && allowed[_from][msg.sender] >= _amount
    && _amount > 0
    && balances[_to] + _amount > balances[_to]) {
      balances[_from] = balances[_from].sub(_amount);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

  //Approves a _spender an _amount of tokens to use
  function approve(address _spender, uint _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  //Returns the remaining allowance of tokens granted to the _spender from the _owner
  function allowance(address _owner, address _spender) public view returns (uint remaining) { return allowed[_owner][_spender]; }
}

interface swap_interface{
    function forcePay(uint _begin, uint _end) public returns (bool);
}

contract Tester {
    address oracleAddress;
    address baseToken1;
    address baseToken2;
    address factory_address;
    address usercontract_address;
    address swapAddress;
    address drct1;
    address drct2;
    swap_interface swap;
    Factory factory;
    Oracle oracle;
    event Print(string _string, uint _value);

    
    function StartTest() public returns(address){
        oracleAddress = new Oracle();
        baseToken1 = new Wrapped_Ether();
        baseToken2 = new Wrapped_Ether();
        factory_address = new Factory();
        return factory_address;
    }
    
    function setVars(uint _startval, uint _endval) public {
        factory = Factory(factory_address);
        oracle = Oracle(oracleAddress);
        factory.setStartDate(1543881600);
        factory.setVariables(1000000000000000,1000000000000000,7,2);
        factory.setBaseTokens(baseToken1,baseToken2);
        factory.setOracleAddress(oracleAddress);
        oracle.StoreDocument(1543881600, _startval);
        oracle.StoreDocument(1544486400,_endval);
        Print('Start Value : ',_startval);
        Print('End Value " ',_endval);
    }
    
    function setTokens(address _drct1,address _drct2){
        drct1 = _drct1; drct2 = _drct2;
        factory.settokens(drct1,drct2);
    }

    function getFactory() public returns (address){
      return factory_address;
    }

   function getUC() public returns (address){
      return usercontract_address;
    }

    function swapAdd(address _swap, bool _isSwap) public returns(address){
      if (_isSwap){
        swapAddress = _swap;
      }
      return swapAddress;
    }


    function setVars2(address _deployer, address _userContract) public{
      factory.setDeployer(_deployer);
      factory.setUserContract(_userContract);
      usercontract_address = _userContract;
    }

    function getWrapped() public returns(address,address){
      return (baseToken1,baseToken2);
    }

    function getDRCT(bool _isLong) public returns(address){
      address drct;
      if(_isLong){
        drct = drct1;
      }
      else{
        drct= drct2;
      }
      return drct;
    }

    function paySwap() public returns(uint,uint){
      for(uint i=0; i < factory.getCount(); i++){
        var x = factory.contracts(i);
          swap = swap_interface(x);
          swap.forcePay(1,100);

      }
      
    Wrapped_Ether wrapped = Wrapped_Ether(baseToken1);
    uint balance_long = wrapped.balanceOf(address(this));
    wrapped = Wrapped_Ether(baseToken2);
    uint balance_short = wrapped.balanceOf(address(this));
    return (balance_long, balance_short);
    }
}


interface Tester_Interface {
  function getFactory() public returns (address);
  function setVars2(address _deployer, address _userContract) public;
  function getUC() public returns (address);
  function swapAdd(address _swap, bool _isSwap) public returns(address);
  function getWrapped() public returns(address,address);
  function getDRCT(bool _isLong) public returns(address);
  function setTokens(address _drct1,address _drct2);
}

contract Tester2 {
  UserContract usercontract;
  address deployer_address;
  address usercontract_address;
  address factory_address;
  Tester_Interface tester;


  function Tester2(address _tester) {
    tester = Tester_Interface(_tester);
    factory_address = tester.getFactory();
    deployer_address = new Deployer(factory_address);
    usercontract_address = new UserContract();
  }

  function setLastVars(){
    tester.setVars2(deployer_address,usercontract_address);
    usercontract = UserContract(usercontract_address);
    usercontract.setFactory(factory_address);
    address drct1 = new DRCT_Token(factory_address);
    address drct2 = new DRCT_Token(factory_address);
    tester.setTokens(drct1,drct2);
  }

}

contract TestParty1 {
  address swap_address;
  address factory_address;
  address usercontract_address;
  address wrapped_long;
  address wrapped_short;
  address user3;
  address drct;
  UserContract usercontract;
  Tester_Interface tester;
  Factory factory;
  Wrapped_Ether wrapped;
  ERC20_Interface dtoken;
  event Print(string _string, uint _value);
  event Print2(string _string, address _value);

  function TestParty1(address _tester) public{
    tester = Tester_Interface(_tester);
    factory_address = tester.getFactory();
    factory = Factory(factory_address);
    swap_address = factory.deployContract();
}

function createSwap() public payable{
    usercontract_address = tester.getUC();
    usercontract = UserContract(usercontract_address);
    usercontract.Initiate.value(msg.value)(swap_address,10000000000000000000,10000000000000000000,0,true );
    tester.swapAdd(swap_address,true);
    user3 = new newTester();
    Print2('New Swap : ',swap_address);
  }

    function transfers() public {
    drct = tester.getDRCT(true);
    dtoken = ERC20_Interface(drct);
    dtoken.transfer(user3,5000);
  }

  function cashOut() public returns(uint, uint,uint,uint){
    (wrapped_long,wrapped_short) = tester.getWrapped();
    wrapped = Wrapped_Ether(wrapped_long);
    uint balance_long = wrapped.balanceOf(address(this));
    uint balance_long3 = wrapped.balanceOf(user3);
    wrapped = Wrapped_Ether(wrapped_short);
    uint balance_short = wrapped.balanceOf(address(this));
    uint balance_short3 = wrapped.balanceOf(user3);
    Print('Long Balance : ',balance_long);
    Print('Transferred Long Balance : ', balance_long3);
    Print('Short Balance : ', balance_short);
    Print('Transferred Short Balance : ', balance_short3);
    return (balance_long, balance_long3, balance_short, balance_short3);
  }
}

contract TestParty2 {

  address swap_address;
  address usercontract_address;
  address wrapped_long;
  address drct;
  address wrapped_short;
  UserContract usercontract;
  Tester_Interface tester;
  address user4;
  Wrapped_Ether wrapped;
  ERC20_Interface dtoken;

  function EnterSwap(address _tester) public payable{
    tester = Tester_Interface(_tester);
    usercontract_address = tester.getUC();
    usercontract = UserContract(usercontract_address);
    swap_address = tester.swapAdd(msg.sender,false);
    usercontract.Enter.value(msg.value)(10000000000000000000,10000000000000000000,false,swap_address);
    user4 = new newTester();
  }

    function transfers() public {
    drct = tester.getDRCT(true);
    dtoken = ERC20_Interface(drct);
    dtoken.transfer(user4,5000);
  }

  function cashOut() public returns(uint, uint,uint,uint){
    (wrapped_long,wrapped_short) = tester.getWrapped();
    wrapped = Wrapped_Ether(wrapped_long);
    uint balance_long = wrapped.balanceOf(address(this));
    uint balance_long4 = wrapped.balanceOf(user4);
    wrapped = Wrapped_Ether(wrapped_short);
    uint balance_short = wrapped.balanceOf(address(this));
    uint balance_short4 = wrapped.balanceOf(user4);
    return (balance_long, balance_long4, balance_short, balance_short4);
  }

}

contract newTester{

}
