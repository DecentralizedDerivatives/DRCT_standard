pragma solidity ^0.4.17;

import "./interfaces/Oracle_Interface.sol";
import "./interfaces/DRCT_Token_Interface.sol";
import "./interfaces/Factory_Interface.sol";
import "./interfaces/ERC20_Interface.sol";
import "./libraries/SafeMath.sol";


/**
*This contract is the specific DRCT base contract that holds the funds of the contract and
*redistributes them based upon the change in the underlying values
*/
contract TokenToTokenSwap {

    using SafeMath for uint256;

    /*Enums*/
    //Describes various states of the Swap
    enum SwapState {
        created,
        started,
        ended
    }
    /*Variables*/
    //The Oracle address (check for list at www.github.com/DecentralizedDerivatives/Oracles)
    address internal oracle_address;

    //Address of the Factory that created this contract
    address public factory_address;
    Factory_Interface internal factory;
    address internal creator;
    //Addresses of ERC20 token
    address internal token_address;
    ERC20_Interface internal token;
    //Enum state of the swap
    SwapState public current_state;
    //Start and end dates of the swaps - format is the same as block.timestamp
    uint internal start_date;
    uint internal end_date;
    uint internal multiplier;
    uint internal duration;
    // pay_to_x refers to the amount of the base token (a or b) to pay to the long or short side based upon the share_long and share_short
    uint internal pay_to_long;
    uint internal pay_to_short;

    uint internal start_value;
    uint internal end_value;
    //Address of created long and short DRCT tokens
    address internal long_token_address;
    address internal short_token_address;
    //Number of DRCT Tokens distributed to both parties
    uint internal num_DRCT_tokens;
    //The notional that the payment is calculated on from the change in the reference rate
    uint public token_amount;

    address internal userContract;

    /*Events*/
    //Emitted when a Swap is created
    event SwapCreation(address _token_address, uint _start_date, uint _end_date, uint _token_amount);
    //Emitted when the swap has been paid out
    event PaidOut(uint pay_to_long, uint pay_to_short);
    /*Functions*/
    modifier onlyState(SwapState expected_state) {
        require(expected_state == current_state);
        _;
    }

    /*Functions*/
    /**
    *@dev Constructor - Run by the factory at contract creation
    *@param _factory_address address of the factory that created this contract
    *@param _creator address of the person who created the contract
    *@param _userContract address of the _userContract that is authorized to interact with this contract
    *@param _start_date start date of the contract
    */
    function TokenToTokenSwap (address _factory_address, address _creator, address _userContract, uint _start_date) public {
        creator = _creator;
        factory_address = _factory_address;
        userContract = _userContract;
        start_date = _start_date;
        current_state = SwapState.created;
    }

     /*
    @dev A getter function for retriving standardized variables from the factory contract
    */
    function showPrivateVars() public view returns (address, uint, address, address, address, address,  uint, uint, uint, uint){
        return (userContract, num_DRCT_tokens,long_token_address,short_token_address, oracle_address, token_address, multiplier, duration, start_date, end_date);
    }

    /**
    *@dev Allows the sender to create the terms for the swap
    *@param _amount Amount of Token that should be deposited for the notional
    *@param _senderAdd States the owner of this side of the contract (does not have to be msg.sender)
    */
  function CreateSwap(
    uint _amount,
    address _senderAdd
    ) public onlyState(SwapState.created) {
    require(
      msg.sender == creator || (msg.sender == userContract && _senderAdd == creator)
    );
    factory = Factory_Interface(factory_address);
    setVars();
    end_date = start_date.add(duration.mul(86400));
    assert(end_date-start_date < 28*86400);
    token_amount = _amount;
    token = ERC20_Interface(token_address);
    assert(token.balanceOf(address(this)) == _amount*2);
    createTokens(creator);
    emit SwapCreation(token_address,start_date,end_date,token_amount);
    current_state = SwapState.started;
  }

    function setVars() internal{
        (oracle_address,duration,multiplier,token_address) = factory.getVariables();
    }

    /*
    *@notice This function is for those entering/creating the swap. Note that the tokens you are entering with
    *do not need to be entered as a variable, but you should ensure that the contract is funded. It will
    *create short and long tokens with a 1:1 ratio. The _party can sell the position they don't want to hold
    *in the exchange. 
    *@dev This function creates the DRCT short and long tokens, and ensures the the _party
    *has funded the contract with the correct amount of the ERC20 tokens. 
    *@param _party address of party creating the short and long token
    */
    function createTokens(address _party) internal {
        uint tokenratio = 1;
        (long_token_address,short_token_address,tokenratio) = factory.createToken(token_amount,_party,start_date);
        num_DRCT_tokens = token_amount.div(tokenratio);
        oracleQuery();
    }

    /*
    *@dev check if the oracle has been queried withing the last day? 
    */
    function oracleQuery() internal returns(bool){
        Oracle_Interface oracle = Oracle_Interface(oracle_address);
        uint _today = now - (now % 86400);
        uint i;
        if(_today >= start_date && start_value == 0){
            for(i=0;i < (_today- start_date)/86400;i++){
                if(oracle.getQuery(start_date+i*86400)){
                    start_value = oracle.retrieveData(start_date+i*86400);
                    return true;
                }
            }
            if(start_value ==0){
                oracle.pushData();
                return false;
            }
        }
        if(_today >= end_date && end_value == 0){
            for(i=0;i < (_today- end_date)/86400;i++){
                if(oracle.getQuery(end_date+i*86400)){
                    end_value = oracle.retrieveData(end_date+i*86400);
                    return true;
                }
            }
            if(end_value ==0){
                oracle.pushData();
                return false;
            }
        }
        return true;
    }

    /*
    *@dev This function calculates the payout of the swap. It can be called after the Swap has been tokenized.
    *The value of the underlying cannot reach zero, but rather can only get within 0.001 * the precision
    *of the Oracle.
    */
    function Calculate() internal {
        uint ratio;
        token_amount = token_amount.mul(995).div(1000);
        if (start_value > 0 && end_value > 0)
            ratio = (end_value).mul(100000).div(start_value);
        else if (end_value > 0)
            ratio = 10e10;
        else if (start_value > 0)
            ratio = 0;
        else
            ratio = 100000;
        ratio = SafeMath.min(200000,ratio);
        pay_to_long = (ratio.mul(token_amount)).div(num_DRCT_tokens).div(100000);
        pay_to_short = (SafeMath.sub(200000,ratio).mul(token_amount)).div(num_DRCT_tokens).div(100000);
    }

    /*
    *@dev This function can be called after the swap is tokenized or after the Calculate function is called.
    *If the Calculate function has not yet been called, this function will call it.
    *The function then pays every token holder of both the long and short DRCT tokens
    *What should we do about zeroed out values? 
    */
    function forcePay(uint _begin, uint _end) public onlyState(SwapState.started) returns (bool) {
       //Calls the Calculate function first to calculate short and long shares
        require(now >= end_date);
        bool ready = oracleQuery();
        if(ready){
            Calculate();
            //Loop through the owners of long and short DRCT tokens and pay them
            DRCT_Token_Interface drct = DRCT_Token_Interface(long_token_address);
            uint count = drct.addressCount(address(this));
            uint loop_count = count < _end ? count : _end;
            //Indexing begins at 1 for DRCT_Token balances
            for(uint i = loop_count-1; i >= _begin ; i--) {
                address long_owner = drct.getHolderByIndex(i, address(this));
                uint to_pay_long = drct.getBalanceByIndex(i, address(this));
                paySwap(long_owner, to_pay_long, true);
            }

            drct = DRCT_Token_Interface(short_token_address);
            count = drct.addressCount(address(this));
            loop_count = count < _end ? count : _end;
            for(uint j = loop_count-1; j >= _begin ; j--) {
                address short_owner = drct.getHolderByIndex(j, address(this));
                uint to_pay_short = drct.getBalanceByIndex(j, address(this));
                paySwap(short_owner, to_pay_short, false);
            }
            if (loop_count == count){
                token.transfer(factory_address, token.balanceOf(address(this)));
                emit PaidOut(pay_to_long,pay_to_short);
                current_state = SwapState.ended;
            }
        }
        return ready;
    }

    /*
    *This function pays the receiver an amount determined by the Calculate function
    *@param _receiver The recipient of the payout
    *@param _amount The amount of token the recipient holds
    *@param _is_long Whether or not the reciever holds a long or short token
    */
    function paySwap(address _receiver, uint _amount, bool _is_long) internal {
        if (_is_long) {
            if (pay_to_long > 0){
                token.transfer(_receiver, _amount.mul(pay_to_long));
                factory.payToken(_receiver,long_token_address);
            }
        } else {
            if (pay_to_short > 0){
                token.transfer(_receiver, _amount.mul(pay_to_short));
                factory.payToken(_receiver,short_token_address);
            }
        }
    }
}