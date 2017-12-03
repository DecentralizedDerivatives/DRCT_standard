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
  function getVariables() public view returns (address oracle_addr, address factory_operator, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr, uint swap_start_date);
}

//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount() public constant returns (uint count);
  function getHolderByIndex(uint _ind) public constant returns (address holder);
  function getBalanceByIndex(uint _ind) public constant returns (uint bal);
  function getIndexByAddress(address _owner) public constant returns (uint index);
  function createToken(uint _supply, address _owner) public;
  function pay(address _party) public;
}

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function RetrieveData(uint _date) public view returns (uint data);
}

//Swap contract
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

  function showPrivateVars() public view returns (uint num_DRCT_long, uint numb_DRCT_short, uint swap_share_long, uint swap_share_short, address long_token_addr, address short_token_addr, address oracle_addr, address token_a_addr, address token_b_addr, uint swap_multiplier, uint swap_duration, uint swap_start_date, uint swap_end_date){
    return (num_DRCT_longtokens, num_DRCT_shorttokens,share_long,share_short,long_token_address,short_token_address, oracle_address, token_a_address, token_b_address, multiplier, duration, start_date, end_date);
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
  function forcePay() public onlyState(SwapState.tokenized) returns (bool) {
    //Calls the Calculate function first to calculate short and long shares
    Calculate();

    //The state at this point should always be SwapState.ready
    require(current_state == SwapState.ready);

    //Loop through the owners of long and short DRCT tokens and pay them

    token = DRCT_Token_Interface(long_token_address);
    uint count = token.addressCount();
    //Indexing begins at 1 for DRCT_Token balances
    for(uint i = 1; i < count; i++) {
      address long_owner = token.getHolderByIndex(i);
      uint to_pay_long = token.getBalanceByIndex(i);
      assert(i == token.getIndexByAddress(long_owner));
      paySwap(long_owner, to_pay_long, true);
    }

    token = DRCT_Token_Interface(short_token_address);
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

//Swap Deployer contract
contract Deployer {
  address owner;

  function Deployer(address _factory) public {
    owner = _factory;
  }

  //TODO - payable?
  function newContract(address _party) public payable returns (address created) {
    require(msg.sender == owner);
    address new_contract = new TokenToTokenSwap(owner, _party);
    return new_contract;
  }
}
