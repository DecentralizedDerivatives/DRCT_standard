pragma solidity ^0.4.17;

import "./libraries/SafeMath.sol";

contract DRCT_Token {

  using SafeMath for uint256;

  /*Structs*/

  //Keeps track of balance amounts in the balances array
  struct Balance {
    address owner;
    uint amount;
  }

  //TODO do we want an "allowed" and "approve" mapping?
  struct Swap {
    uint token_id; //TODO not necessary?
    uint total_supply;
    bool active;
    Balance[] balances;
    mapping(address => uint) balance_index;
  }

  /*Variables*/

  //Keeps track of balances for each deployed Swap contract
  Swap[] swaps;

  //Address for the factory contract
  address public master_contract;

  /*Events*/

  event Transfer(address indexed _from, address indexed _to, uint _value, uint _swap_id);

  /*Modifiers*/

  modifier onlyMaster() {
    require(msg.sender == master_contract);
    _;
  }

  modifier onlyExistingSwap(uint _token_id) {
    require(_token_id < swaps.length);
    _;
  }

  modifier onlyActiveSwap(uint _token_id) {
    require(swaps[_token_id].active);
    _;
  }

  /*Functions*/

  //Constructor
  function DRCT_Token(address _factory) public {
    //Set the master contract
    master_contract = _factory;
  }

  //TODO description
  function createToken(uint _supply, address _owner) public onlyMaster() {
    uint new_token_id = swaps.length;
    swaps.push(Swap({
      token_id: new_token_id,
      total_supply: _supply,
      active: true,
      balances: []
    }));
    swaps[new_token_id].balances.push(Balance({
      owner: 0,
      amount: 0
    }));
    swaps[new_token_id].balance_index[_owner] = swaps[new_token_id].balances.length;
    swaps[new_token_id].balances.push(Balance({
      owner: _owner,
      amount: _supply
    }));
  }

  //TODO description
  function balanceOf(address _owner, uint _token_id) public onlyExistingSwap(_token_id) constant returns (uint balance) {
    uint ind = swaps[_token_id].balance_index[_owner];
    return ind == 0 ? 0 : swaps[_token_id].balances[ind].amount;
  }

  //TODO description
  function totalSupply(uint _token_id) public onlyExistingSwap(_token_id) constant returns (uint _total_supply) {
    return swaps[_token_id].total_supply;
  }

  //TODO description
  function transfer(address _to, uint _amount, uint _token_id) public onlyExistingSwap(_token_id) onlyActiveSwap(_token_id) returns (bool success) {
    uint owner_ind = swaps[_token_id].balance_index[msg.sender];
    uint to_ind = swaps[_token_id].balance_index[_to];

    if (
      _to == msg.sender ||
      _to == address(0) ||
      owner_ind == 0 ||
      _amount == 0 ||
      swaps[_token_id].balances[owner_ind].amount < _amount
    ) return false;

    transferHelper(msg.sender, _to, _amount, to_ind, owner_ind, _token_id);
    return true;
  }

  //TODO description
  function transferHelper(address _from, address _to, uint _amount, uint _to_ind, uint _owner_ind, uint _token_id) internal {
    Swap storage swap = swaps[_token_id];
    if (_to_ind == 0) {
      //If the sender will have a balance of 0 post-transfer, we remove their index from balance_index
      //and assign it to _to, representing a complete transfer of tokens from msg.sender to _to
      //Otherwise, we add the new recipient to the balance_index and balances
      if (swap.balances[_owner_ind].amount.sub(_amount) == 0) {
        swap.balance_index[_to] = _owner_ind;
        swap.balances[_owner_ind].owner = _to;
        delete swap.balance_index[_from];
      } else {
        swap.balance_index[_to] = swap.balances.length;
        swap.balances.push(Balance({
          owner: _to,
          amount: _amount
        }));
        swap.balances[_owner_ind].amount = swap.balances[_owner_ind].amount.sub(_amount);
      }
    //The recipient already has tokens
    } else {
      //If the sender will no longer have tokens, we want to remove them from the balance_indexes
      //Because the _to address is already a holder, we want to swap the last holder into the
      //sender's slot, for easier iteration
      //Otherwise, we want to simply update the balance for the recipient
      if (swap.balances[_owner_ind].amount.sub(_amount) == 0) {
        swap.balances[_to_ind].amount = swap.balances[_to_ind].amount.add(_amount);

        address last_address = swap.balances[swap.balances.length - 1].owner;
        swap.balance_index[last_address] = _owner_ind;
        swap.balances[_owner_ind] = swap.balances[swap.balances.length - 1];
        swap.balances.length = swap.balances.length.sub(1);

        //The sender will no longer have a balance index
        delete swap.balance_index[_from];
      } else {
        swap.balances[_to_ind].amount = swap.balances[_to_ind].amount.add(_amount);
        swap.balances[_owner_ind].amount = swap.balances[_owner_ind].amount.sub(_amount);
      }
    }
    Transfer(_from, _to, _amount, _token_id);
  }

  //TODO description
  function pay(address _party, uint _token_id) public onlyMaster() onlyExistingSwap(_token_id) {
    //TODO function body

    //If the swap is active, set it to inactive to halt transfers
    swaps[_token_id].active = false;
  }

  //Returns the length of the balances array
  function addressCount(uint _token_id) public onlyExistingSwap(_token_id) constant returns (uint count) { return swaps[_token_id].balances.length; }

  //Returns the address associated with a particular index in balance_index
  function getHolderByIndex(uint _ind, uint _token_id) public onlyExistingSwap(_token_id) constant returns (address holder) { return swaps[_token_id].balances[_ind].owner; }

  //Returns the balance associated with a particular index in balance_index
  function getBalanceByIndex(uint _ind, uint _token_id) public onlyExistingSwap(_token_id) constant returns (uint bal) { return swaps[_token_id].balances[_ind].amount; }

  //Returns the index associated with the _owner address
  function getIndexByAddress(address _owner, uint _token_id) public onlyExistingSwap(_token_id) constant returns (uint index) { return swaps[_token_id].balance_index[_owner]; }

}
