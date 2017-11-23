pragma solidity ^0.4.17;

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
  address public operator;

  //The Oracle address (check for list at www.github.com/DecentralizedDerivatives/Oracles)
  address public oracle_address;
  Oracle oracle;

  //Address of the Factory that created this contract
  address public factory_address;
  Factory_Interface factory;

  //Addresses of parties going short and long the rate
  address public long_party;
  address public short_party;

  //Enum state of the swap
  SwapState current_state;

  //Start and end dates of the swaps - format is the same as block.timestamp
  uint public start_date;
  uint public end_date;

  //This is the amount that the change will be calculated on.  10% change in rate on 100 Ether notional is a 10 Ether change
  uint public multiplier;

  /*TODO description*/
  uint public share_long;
  uint public share_short;

  /*TODO description*/
  uint pay_to_short_a;
  uint pay_to_long_a;
  uint pay_to_long_b;
  uint pay_to_short_b;

  //Address of created long and short DRCT tokens
  address public long_token_address;
  address public short_token_address;

  //Dsitributed DRCT tokens for the long and short parties
  DRCT_Interface long_token;
  DRCT_Interface short_token;

  //Number of DRCT Tokens distributed to both parties
  uint public num_DRCT_longtokens;
   uint public num_DRCT_shorttokens;

  //Addresses of ERC20 tokens used to enter the swap
  address public token_a_address;
  address public token_b_address;

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

  /*Events*/

  //Emitted when a Swap is created
  event SwapCreation(address _token_a, address _token_b, uint _start_date, uint _end_date, address _creating_party);
  //Emitted when a second party enteres the Swap
  event SwapEntered(address _token_a, address _token_b, uint _start_date, uint _end_date, address _entering_party);
  //Emitted when the swap has been paid out
  event PaidOut(address _long_token, address _short_token);

  /*Modifiers*/

  //Will proceed only if the contract is in the expected state
  modifier onlyState(SwapState expected_state) {
    require(expected_state == current_state);
    _;
  }

  //Will proceed only if the sender is one of the participating parties, or the operator
  modifier onlyPartiesOrOperator() {
    require(
      msg.sender == short_party ||
      msg.sender == long_party ||
      msg.sender == operator
    );
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
  function TokenToTokenSwap(address _o_address, address _operator, address _creator, address _factory, uint _duration,uint _start_date, uint _multiplier,address _token_a_address,address _token_b_address) public {
    current_state = SwapState.created;
    oracle_address = _o_address;
    oracle = Oracle(_o_address);
    factory_address = _factory;
    factory = Factory_Interface(_factory);
    creator = _creator;
    operator = _operator;
    duration = _duration;
    multiplier = _multiplier;
    token_a_address = _token_a_address;
    token_b_address = _token_b_address;
    start_date = _start_date;
    end_date = start_date.add(duration.mul(86400));

    require(token_a_address != token_b_address);
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
    token_a_amount = _amount_a;
    token_b_amount = _amount_b;

    premium = msg.value;
    token_a = ERC20_Interface(token_a_address);
    token_a_party = msg.sender;
    if (_sender_is_long)
      long_party = msg.sender;
    else
      short_party = msg.sender;
    current_state = SwapState.open;
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
  function createTokens() public onlyState(SwapState.started) onlyPartiesOrOperator() {

    //Ensure the contract has been funded by tokens a and b
    require(
      now <= start_date &&
      token_a.balanceOf(address(this)) >= token_a_amount &&
      token_b.balanceOf(address(this)) >= token_b_amount
    );

    tokenize(long_party);
    tokenize(short_party);
    current_state = SwapState.tokenized;
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
      long_token = DRCT_Interface(long_token_address);
      num_DRCT_longtokens = token_a_amount.div(tokenratio);
    } else if (_creator == short_party) {
      (short_token_address,tokenratio) = factory.createToken(token_b_amount, _creator,false);
      short_token = DRCT_Interface(short_token_address);
      num_DRCT_shorttokens = token_b_amount.div(tokenratio);
    }
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
  * This function calculates the payout of the swap. It can be called after the Swap has been tokenized.
  * The value of the underlying cannot reach zero, but rather can only get within 0.001 * the precision
  * of the Oracle.
  */
  function Calculate() internal {
    //require(now >= end_date);

    uint start_value = RetrieveData(start_date);
    uint end_value = RetrieveData(end_date);

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
      ratio = SafeMath.min(99999, (share_long).sub(100000));
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_a = (SafeMath.sub(100000,ratio)).mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_long_a = ratio.mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_short_b = 0;
    } else {
      ratio = SafeMath.min(99999, (share_short).sub(100000));
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
    uint long_count = long_token.addressCount();
    uint short_count = short_token.addressCount();
    //Indexing begins at 1 for DRCT_Token balances
    for(uint i = 1; i < long_count; i++) {
      address long_owner = long_token.getHolderByIndex(i);
      uint to_pay_long = long_token.getBalanceByIndex(i);
      assert(i == long_token.getIndexByAddress(long_owner));
      paySwap(long_owner, to_pay_long, true);
    }
    for(uint j = 1; j < short_count; j++) {
      address short_owner = short_token.getHolderByIndex(j);
      uint to_pay_short = short_token.getBalanceByIndex(j);
      assert(j == short_token.getIndexByAddress(short_owner));
      paySwap(short_owner, to_pay_short, false);
    }

    token_a.transfer(operator, token_a.balanceOf(address(this)));
    token_b.transfer(operator, token_b.balanceOf(address(this)));

    PaidOut(long_token, short_token);
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
    require(
      current_state != SwapState.ended &&
      msg.sender == long_party ||
      msg.sender == short_party
    );

    /*
    * If the current state is open, then the other party has not entered and the creator of the swap can restart with new values
    * Otherwise, if the two parties agree to an Exit and have not distributed their DRCT tokens, they are sent their respective tokens
    * and the swap is cancelled
    */
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
        token_a.transfer(token_a_party, token_a.balanceOf(address(this)));
        token_b.transfer(token_b_party, token_b.balanceOf(address(this)));
        current_state = SwapState.ended;
      }
    } else if (msg.sender == operator){
        require (long_token.balanceOf(address(this)) == num_DRCT_longtokens &&
        short_token.balanceOf(address(this)) == num_DRCT_shorttokens) ;
        token_a.transfer(operator, token_a_amount);
        token_b.transfer(operator, token_b_amount);
        current_state = SwapState.ended;
      }
  }

  /*
  * Retrieves data from the oracle based on a given date
  *
  * @param "_date": Date to retrieve values for, in block.timestamp format
  */
  function RetrieveData(uint _date) public constant returns (uint data) {
    uint value = oracle.oracle_values(_date);
    return value;
  }

}
