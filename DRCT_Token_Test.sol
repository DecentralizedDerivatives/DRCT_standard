pragma solidity ^0.4.18;

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

contract DRCT_Token {

  using SafeMath for uint256;

  /*Structs */

  //Keeps track of balance amounts in the balances array
  struct Balance {
    address owner;
    uint amount;
    /*DeepBalance[] deepBalance;*/
  }

  /*struct DeepBalance{
    address swap;
    uint amount;
  }

  struct SwapList{
    address[] parties;
  }*/

  address public master_contract;

  uint public total_supply;

  /*Balance[] balances;
  mapping(address => mapping (address => uint)) public allowed;
  mapping(address => uint) public balance_index;
  mapping(address => mapping(address => uint)) deep_index;
  mapping(address => mapping(address => uint)) public swap_index;
  mapping(address => SwapList) swaps;*/

  mapping(address => Balance[]) swap_balances;
  mapping(address => address[]) user_swaps;
  mapping(address => mapping(address => uint)) swap_user_index;

  mapping(address => uint) user_total_balances; //TODO required?
  mapping(address => mapping(address => uint)) allowed;

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  modifier onlyMaster() {
    require(msg.sender == master_contract);
    _;
  }

  /*Functions*/

  /*function updatedeepBalances(address short_party, address long_party, uint _amount) internal{
      address swap_address;
        //loop backwards and drain each swap of amount when transfering
      uint ind = balance_index[short_party];
      for (uint i=balances[ind].deepBalance.length; i >0; i--){
          uint amount2 =_amount;
          while (amount2>0){
            if (balances[ind].deepBalance[i].amount > amount2){
              balances[ind].deepBalance[i].amount -= amount2;
              swap_address = balances[ind].deepBalance[i].swap;
              amount2 == 0;
            }
            else{
              amount2 -= balances[ind].deepBalance[i].amount;
              swap_address = balances[ind].deepBalance[i].swap;
              delete balances[ind].deepBalance[i];
              delete deep_index[short_party][swap_address];
              delete swaps[swap_address].parties[swap_index[swap_address][short_party]];
              delete swap_index[swap_address][short_party];
            }
          }
      }
      ind = balance_index[short_party];
        if (deep_index[long_party][swap_address]>0){
        balances[ind].deepBalance[deep_index[long_party][swap_address]].amount = _amount;
      }
      else{
        uint newlen = balances[ind].deepBalance.length + 1;
        balances[ind].deepBalance[newlen].amount = _amount;
        balances[ind].deepBalance[newlen].swap = swap_address;
        deep_index[long_party][swap_address] = newlen;
        swap_index[swap_address][long_party] = swaps[swap_address].parties.length + 1;
        uint _ind2 = swaps[swap_address].parties.length + 1;
        swaps[swap_address].parties[_ind2] = long_party;
      }
  }*/

  //Called by the factory contract, and pays out to a _party
  /*function pay(address _party, address _swap) public {
    require(msg.sender == master_contract);
    uint ind_num = deep_index[_party][_swap];
    uint ind = balance_index[_party];
    balances[ind].amount = balances[ind].amount.sub(balances[ind].deepBalance[ind_num].amount);
    delete balances[ind].deepBalance[ind_num];
    delete deep_index[_party][_swap];
    delete swaps[_swap].parties[swap_index[_swap][_party]];
    delete swap_index[_swap][_party];
  }*/

  //Constructor
  function DRCT_Token(address _factory) public {
    //Sets values for token name and token supply, as well as the master_contract, the swap.
    master_contract = _factory;
  }

  //TODO - description
  function createTokenTest(uint _supply, address _owner, address _swap) public onlyMaster() {
    total_supply = total_supply.add(_supply);
    user_swaps[msg.sender].push(_swap);
    user_total_balances[msg.sender] = user_total_balances[msg.sender].add(_supply);
    swap_balances[_swap].push(Balance({
      owner: 0,
      amount: 0
    }));
    swap_user_index[_swap][msg.sender] = 1;
    swap_balances[_swap].push(Balance({
      owner: _owner,
      amount: _supply
    }));
  }

  // Two options here - we can either store another mapping with users current balances, or we can iterate over their swap-to-swap balances in this function
  // I have implemented the latter in this version of the function, and the former in the function below
  //TODO - description
  function balanceOfTwo(address _owner) public constant returns (uint balance) {
    address[] memory owner_swaps = user_swaps[_owner];
    uint bal = 0;
    for (uint i = 0; i < owner_swaps.length; i++) {
      //Get user balance index for the current swap:
      uint bal_index = swap_user_index[owner_swaps[i]][_owner];
      bal = bal.add(swap_balances[owner_swaps[i]][bal_index].amount);
    }
    return bal;
  }

  //TODO - description
  function balanceOf(address _owner) public constant returns (uint balance) { return user_total_balances[_owner]; }

  //TODO - description
  function totalSupply() public constant returns (uint _total_supply) { return total_supply; }

  /*function transferHelper(address _from, address _to, uint _amount, uint _to_ind, uint _owner_ind) internal {

  }*/

  //TODO - description
  /*function transferHelper(address _from, address _to, uint _amount, uint _to_ind, uint _owner_ind) internal {
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
        balances[balances.length].owner = _to;
        balances[balances.length].amount = _amount;
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
    updatedeepBalances(_from,_to,_amount);

  }*/

  /*
  * Allows a holder of tokens to send them to another address. The management of addresses and balances is handled in the transferHelper function.
  *
  * @param "_to": The address to send tokens to
  * @param "_amount": The amount of tokens to send
  */
  /*function transfer(address _to, uint _amount) public returns (bool success) {
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
  }*/

  /*
  * This function allows an address with the necessary allowance of funds to send tokens to another address on
  * the _from address's behalf. The management of addresses and balances is handled in the transferHelper function.
  *
  * @param "_from": The address to send funds from
  * @param "_to": The address which will receive funds
  * @param "_amount": The amount of tokens sent from _from to _to
  */
  /*function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
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
  }*/

  /*
  * This function allows the sender to approve an _amount of tokens to be spent by _spender
  *
  * @param "_spender": The address which will have transfer rights
  * @param "_amount": The amount of tokens to allow _spender to spend
  */
  /*function approve(address _spender, uint _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }*/

  /*//Returns the length of the balances array
  function addressCount() public constant returns (uint count) { return balances.length; }

  //Returns the address associated with a particular index in balance_index
  function getHolderByIndex(uint _ind) public constant returns (address holder) { return balances[_ind].owner; }

  //Returns the balance associated with a particular index in balance_index
  function getBalanceByIndex(uint _ind) public constant returns (uint bal) { return balances[_ind].amount; }

  //Returns the index associated with the _owner address
  function getIndexByAddress(address _owner) public constant returns (uint index) { return balance_index[_owner]; }

  function partyCount(address _swap) public constant returns(uint count){
    return swaps[_swap].parties.length;
  }
  function getDeepHolderByIndex(uint _ind, address _swap) public constant returns (address holder) { return swaps[_swap].parties[_ind]; }

  //Returns the balance associated with a particular index in balance_index
  function getDeepBalance(uint _ind, address _party, address _swap) public constant returns (uint bal) { return balances[_ind].deepBalance[deep_index[_party][_swap]].amount; }


  //Returns the allowed amount _spender can spend of _owner's balance
  function allowance(address _owner, address _spender) public constant returns (uint amount) { return allowed[_owner][_spender]; }*/
}
