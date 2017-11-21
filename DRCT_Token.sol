pragma solidity ^0.4.17;
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
