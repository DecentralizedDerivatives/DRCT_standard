pragma solidity ^0.4.17;

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

/*Factory.sol interface for TokenToTokenSwap contract*/
interface Factory_Interface {
  function createToken(uint _supply, address _owner, bool long) public returns (address created, uint tokenratio);
  function payToken(address _party, bool long) public;
  function deployContract(address new_contract) payable public;
  function getVariables() public returns(address _oracle_address,address _operator,uint _duration,uint _multiplier,address _token_a_address,address _token_b_address,uint _start_date);
}

interface Oracle_Interface{
  function RetrieveData(uint _date) public constant returns (uint data);
}

interface DRCT_Interface {

  //ERC20 functions
  function totalSupply() public constant returns (uint total_supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
  function approve(address _spender, uint _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint amount);


  //DRCT_Token functions - descriptions can be found in DRCT_Token.sol
  function addressCount() public constant returns (uint count);
  function getHolderByIndex(uint _ind) public constant returns (address holder);
  function getBalanceByIndex(uint _ind) public constant returns (uint bal);
  function getIndexByAddress(address _owner) public constant returns (uint index);
  function createToken(uint _supply, address _owner) public;
  function pay(address _party) public;

  //Events
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event StateChanged(bool _success, string _message);

}




interface ERC20_Interface {

    function totalSupply() public constant returns (uint total_supply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}


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

contract Oracle {

  /*Variables*/

  //Owner of the oracle
  address private owner;

  //Mapping of documents stored in the oracle
  mapping(uint => uint) public oracle_values;

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

    function RetrieveData(uint _date) public constant returns (uint data) {
    uint value = oracle_values[_date];
    return value;
  }


}
contract DRCT_Token {

  using SafeMath for uint256;

  /*Structs */

  //Keeps track of balance amounts in the balances array
  struct Balance {
    address owner;
    uint amount;
  }

  /*Variables*/

  //Address for the token-to-token swap contract
  address public master_contract;

  //ERC20 Fields
  uint public total_supply;

  //ERC20 fields - allowed and balances
  //Balance is an array here so it can be iterated over from the forcePay function in the Swap contract
  Balance[] public balances;
  mapping(address => mapping (address => uint)) public allowed;

  //This mapping keeps track of where an address is in the balances array
  mapping(address => uint) public balance_index;

  /*Events*/

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  /*Functions*/

  /*
  * Constructor: called by the createTokens fucntion in the Swap contract
  * @param "_total_supply": The total number of tokens to create
  * @param "_name": The name of the token
  */
  function pay(address _party) public {
    require (msg.sender== master_contract);
    balances.push(Balance({
      owner: _party,
      amount: 0
    }));
  }

  function DRCT_Token(address _factory) public {
    //Sets values for token name and token supply, as well as the master_contract, the swap.
    master_contract = _factory;
    //Sets the balance index for the _owner, pushes a '0' index to balances, and pushes
    //the _owner to balances, giving them the _total_supply
    balances.push(Balance({
      owner: 0,
      amount: 0
    }));
  }

  function createToken(uint _supply, address _owner) public{
    require(msg.sender == master_contract);
    total_supply += _supply;
    balance_index[_owner] = balances.length;
      balances.push(Balance({
        owner: _owner,
        amount: _supply
      }));
  }

  //Returns the balance of _owner
  function balanceOf(address _owner) public constant returns (uint balance) {
    uint ind = balance_index[_owner];
    return ind == 0 ? 0 : balances[ind].amount;
  }

  //Returns the total amount of tokens
  function totalSupply() public constant returns (uint _total_supply) { return total_supply; }

  /*
  * This function allows a holder of the token to transfer some of that token to another address.
  * Management of addresses and balances rely on a dynamic Balance array, which holds Balance structs,
  * and a mapping, balance_index, which keeps track of which addresses have which indices in the balances mapping.
  * The purpose of this deviation from normal ERC20 standards is to allow the owners of the DRCT Token to be efficiently iterated over.
  *
  * @param "_from": The address from which the transfer will come
  * @param "_to": The address being sent the tokens
  * @param "_amount": The amount of tokens to send to _to
  * @param "_to_ind": The index of the receiver in the balances array
  * @param "_owner_ind": The index of the sender in the balances array
  */
  function transferHelper(address _from, address _to, uint _amount, uint _to_ind, uint _owner_ind) internal {
    if (_to_ind == 0) {
      //If the sender will have a balance of 0 post-transfer, we remove their index from balance_index
      //and assign it to _to, representing a complete transfer of tokens from msg.sender to _to
      //Otherwise, we add the new recipient to the balance_index and balances
      if (balances[_owner_ind].amount.sub(_amount) == 0) {
        balance_index[_to] = _owner_ind;
        balances[_owner_ind].owner = _to;
        delete balance_index[_from];
      } else {
        balance_index[_to] = balances.length;
        balances.push(Balance({
          owner: _to,
          amount: _amount
        }));
        balances[_owner_ind].amount = balances[_owner_ind].amount.sub(_amount);
      }
    //The recipient already has tokens
    } else {
      //If the sender will no longer have tokens, we want to remove them from the balance_indexes
      //Because the _to address is already a holder, we want to swap the last holder into the
      //sender's slot, for easier iteration
      //Otherwise, we want to simply update the balance for the recipient
      if (balances[_owner_ind].amount.sub(_amount) == 0) {
        balances[_to_ind].amount = balances[_to_ind].amount.add(_amount);

        address last_address = balances[balances.length - 1].owner;
        balance_index[last_address] = _owner_ind;
        balances[_owner_ind] = balances[balances.length - 1];
        balances.length = balances.length.sub(1);

        //The sender will no longer have a balance index
        delete balance_index[_from];
      } else {
        balances[_to_ind].amount = balances[_to_ind].amount.add(_amount);
        balances[_owner_ind].amount = balances[_owner_ind].amount.sub(_amount);
      }
    }
    Transfer(_from, _to, _amount);

  }

  /*
  * Allows a holder of tokens to send them to another address. The management of addresses and balances is handled in the transferHelper function.
  *
  * @param "_to": The address to send tokens to
  * @param "_amount": The amount of tokens to send
  */
  function transfer(address _to, uint _amount) public returns (bool success) {
    uint owner_ind = balance_index[msg.sender];
    uint to_ind = balance_index[_to];

    if (
      _to == msg.sender ||
      _to == address(0) ||
      owner_ind == 0 ||
      _amount == 0 ||
      balances[owner_ind].amount < _amount
    ) return false;

    transferHelper(msg.sender, _to, _amount, to_ind, owner_ind);
    return true;
  }

  /*
  * This function allows an address with the necessary allowance of funds to send tokens to another address on
  * the _from address's behalf. The management of addresses and balances is handled in the transferHelper function.
  *
  * @param "_from": The address to send funds from
  * @param "_to": The address which will receive funds
  * @param "_amount": The amount of tokens sent from _from to _to
  */
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    uint from_ind = balance_index[_from];
    uint to_ind = balance_index[_to];

    if (
      _to == address(0) ||
      _amount == 0 ||
      allowed[_from][msg.sender] < _amount ||
      from_ind == 0 ||
      balances[from_ind].amount < _amount
    ) return false;

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);

    //If the _from address is the same as the _to address, we simply deduct from the sender's allowed balance and return
    if (_from == _to)
      return true;

    transferHelper(_from,_to,_amount,to_ind,from_ind);
    return true;
  }

  /*
  * This function allows the sender to approve an _amount of tokens to be spent by _spender
  *
  * @param "_spender": The address which will have transfer rights
  * @param "_amount": The amount of tokens to allow _spender to spend
  */
  function approve(address _spender, uint _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  //Returns the length of the balances array
  function addressCount() public constant returns (uint count) { return balances.length; }

  //Returns the address associated with a particular index in balance_index
  function getHolderByIndex(uint _ind) public constant returns (address holder) { return balances[_ind].owner; }

  //Returns the balance associated with a particular index in balance_index
  function getBalanceByIndex(uint _ind) public constant returns (uint bal) { return balances[_ind].amount; }

  //Returns the index associated with the _owner address
  function getIndexByAddress(address _owner) public constant returns (uint index) { return balance_index[_owner]; }

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
  SwapState current_state;

  //Start and end dates of the swaps - format is the same as block.timestamp
  uint start_date;
  uint end_date;

  //This is the amount that the change will be calculated on.  10% change in rate on 100 Ether notional is a 10 Ether change
  uint multiplier;

  /*TODO description*/
  uint public share_long;
  uint public share_short;

  /*TODO description*/
  uint pay_to_short_a;
  uint pay_to_long_a;
  uint pay_to_long_b;
  uint pay_to_short_b;

  //Address of created long and short DRCT tokens
  address long_token_address;
  address short_token_address;

  //Number of DRCT Tokens distributed to both parties
  uint public num_DRCT_longtokens;
  uint public num_DRCT_shorttokens;

  //Addresses of ERC20 tokens used to enter the swap
  address token_a_address;
  address  token_b_address;

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
  DRCT_Interface token;

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
  function TokenToTokenSwap (address _factory_address, address _creator) public {
    current_state = SwapState.created;
    creator =_creator;
    factory_address = _factory_address;
  }

  function showPrivateVars() public returns (address _long_token_address, address _short_token_address, address _oracle_adress, address _token_a_address, address _token_b_address, uint _multiplier, uint _duration,uint _start_date, uint _end_date){
    return (long_token_address,short_token_address, oracle_address, token_a_address, token_b_address, multiplier, duration, start_date, end_date);
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
    bool _sender_is_long
    ) payable public onlyState(SwapState.created) {

    //The Swap is meant to take place within 28 days
    require(
      msg.sender == creator
    );
    factory = Factory_Interface(factory_address);
    setVars();
    end_date = start_date.add(duration.mul(86400));
    token_a_amount = _amount_a;
    token_b_amount = _amount_b;

    premium = this.balance;
    token_a = ERC20_Interface(token_a_address);
    token_a_party = msg.sender;
    if (_sender_is_long)
      long_party = msg.sender;
    else
      short_party = msg.sender;
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
    bool _sender_is_long
    ) public onlyState(SwapState.open) {

    //Require that all of the information of the swap was entered correctly by the entering party
    require(
      token_a_amount == _amount_a &&
      token_b_amount == _amount_b &&
      token_a_party != msg.sender
    );

    token_b = ERC20_Interface(token_b_address);
    token_b_party = msg.sender;

    //Set the entering party as the short or long party
    if (_sender_is_long) {
      require(long_party == 0);
      long_party = msg.sender;
    } else {
      require(short_party == 0);
      short_party = msg.sender;
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
    //Uses the factory to deploy a DRCT Token contract, which we cast to the DRCT_Interface
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
  function forcePay() public onlyState(SwapState.tokenized) returns (bool) {
    //Calls the Calculate function first to calculate short and long shares
    Calculate();

    //The state at this point should always be SwapState.ready
    require(current_state == SwapState.ready);

    //Loop through the owners of long and short DRCT tokens and pay them
    
    token = DRCT_Interface(long_token_address);
    uint count = token.addressCount();
    //Indexing begins at 1 for DRCT_Token balances
    for(uint i = 1; i < count; i++) {
      address long_owner = token.getHolderByIndex(i);
      uint to_pay_long = token.getBalanceByIndex(i);
      assert(i == token.getIndexByAddress(long_owner));
      paySwap(long_owner, to_pay_long, true);
    }

    token = DRCT_Interface(short_token_address);
    count = token.addressCount();
    for(uint j = 1; j < count; j++) {
      address short_owner = token.getHolderByIndex(j);
      uint to_pay_short = token.getBalanceByIndex(j);
      assert(j == token.getIndexByAddress(short_owner));
      paySwap(short_owner, to_pay_short, false);
    }

    token_a.transfer(operator, token_a.balanceOf(address(this)));
    token_b.transfer(operator, token_b.balanceOf(address(this)));

    PaidOut(long_token_address, short_token_address);
    current_state = SwapState.ended;
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
    function withdraw(uint _value) public{
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
  function allowance(address _owner, address _spender) constant public returns (uint remaining) { return allowed[_owner][_spender]; }

}

