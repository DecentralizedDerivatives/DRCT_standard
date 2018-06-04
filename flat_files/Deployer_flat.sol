
pragma solidity ^0.4.23;



contract CloneFactory {

  address internal owner;

  event CloneCreated(address indexed target, address clone);

  constructor() public{
    owner = msg.sender;
  }


    /*Modifiers*/
  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }


  function setOwner(address _owner) public onlyOwner(){
    owner = _owner;
  }

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[26 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
  }
}

contract Deployer is CloneFactory {
    /*Variables*/
    address internal factory;
    address public swap;
    
    /*Functions*/
    /**
     *@dev Deploys the factory contract 
     *@param _factory is the address of the factory contract
    */    
    constructor(address _factory) public {
        factory = _factory;
        swap = new TokenToTokenSwap(address(this),msg.sender,address(this),now);
    }

    function updateSwap(address _addr) public onlyOwner() {
        swap = _addr;
    }
    
    event Deployed(address _swap, address _clone);
    
    //"0xca35b7d915458ef540ade6068dfe2f44e8fa733c","0xca35b7d915458ef540ade6068dfe2f44e8fa733c",1527811200
    /**
    *@notice The function creates a new contract
    *@dev It ensures the new contract can only be created by the factory
    *@param _party address of user creating the contract
    *@param user_contract address of userContract.sol 
    *@param _start_date contract start date
    *@return returns the address for the new contract
    */
    function newContract(address _party, address _user, uint _start) public returns (address) {
        address new_swap = createClone(swap);
        //TokenToTokenSwap(new_swap).init(factory, _party, _user, _start);
        emit Deployed(swap, new_swap);
        return new_swap;
    }

    /**
     *@dev Set variables if the owner is the factory contract
     *@param _factory address
     *@param _owner address
    */
    function setVars(address _factory, address _owner) public {
        require (msg.sender == owner);
        factory = _factory;
        owner = _owner;
    }
}


interface Oracle_Interface{
  function getQuery(uint _date) external view returns(bool);
  function retrieveData(uint _date) external view returns (uint);
  function pushData() external payable;
}

interface DRCT_Token_Interface {
  function addressCount(address _swap) external constant returns (uint);
  function getBalanceAndHolderByIndex(uint _ind, address _swap) external constant returns (uint, address);
  function getIndexByAddress(address _owner, address _swap) external constant returns (uint);
  function createToken(uint _supply, address _owner, address _swap) external;
  function pay(address _party, address _swap) external;
  function partyCount(address _swap) external constant returns(uint);
}

interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) external returns (address,address, uint);
  function payToken(address _party, address _token_add) external;
  function deployContract(uint _start_date) external payable returns (address);
   function getBase() external view returns(address);
  function getVariables() external view returns (address, uint, uint, address);
  function isWhitelisted(address _member) external view returns (bool);
}

interface ERC20_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
}

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

library TokenLibrary{

    using SafeMath for uint256;

    /*Variables*/
    enum SwapState {
            created,
            started,
            ended
    }
    
    /*Structs*/
    struct SwapStorage{
        //The Oracle address (check for list at www.github.com/DecentralizedDerivatives/Oracles)
        address oracle_address;
        //Address of the Factory that created this contract
        address factory_address;
        Factory_Interface factory;
        address creator;
        //Addresses of ERC20 token
        address token_address;
        ERC20_Interface token;
        //Enum state of the swap
        SwapState current_state;
        //Start date, end_date, multiplier duration,start_value,end_value,fee
        uint[7] contract_details;
        // pay_to_x refers to the amount of the base token (a or b) to pay to the long or short side based upon the share_long and share_short
        uint pay_to_long;
        uint pay_to_short;
        //Address of created long and short DRCT tokens
        address long_token_address;
        address short_token_address;
        //Number of DRCT Tokens distributed to both parties
        uint num_DRCT_tokens;
        //The notional that the payment is calculated on from the change in the reference rate
        uint token_amount;
        address userContract;

    }
    /*Events*/
    event SwapCreation(address _token_address, uint _start_date, uint _end_date, uint _token_amount);
    //Emitted when the swap has been paid out
    event PaidOut(uint pay_to_long, uint pay_to_short);

    /*Functions*/
    /**
    *@param _factory_address
    *@param _creator address of swap creator
    *@param _userContract 
    *@param _start_date swap start date
    */
    function startSwap (SwapStorage storage self, address _factory_address, address _creator, address _userContract, uint _start_date) internal {
        self.creator = _creator;
        self.factory_address = _factory_address;
        self.userContract = _userContract;
        self.contract_details[0] = _start_date;
        self.current_state = SwapState.created;
    }

     /**
    @dev A getter function for retriving standardized variables from the factory contract
    */
    function showPrivateVars(SwapStorage storage self) internal view returns (address[5],uint, uint, uint, uint, uint){
        return ([self.userContract, self.long_token_address,self.short_token_address, self.oracle_address, self.token_address], self.num_DRCT_tokens, self.contract_details[2], self.contract_details[3], self.contract_details[0], self.contract_details[1]);
    }

    /**
    *@dev Allows the sender to create the terms for the swap
    *@param _amount Amount of Token that should be deposited for the notional
    *@param _senderAdd States the owner of this side of the contract (does not have to be msg.sender)
    */
    function createSwap(SwapStorage storage self,uint _amount, address _senderAdd) internal{
        require(self.current_state == SwapState.created && msg.sender == self.creator  && _amount > 0 || (msg.sender == self.userContract && _senderAdd == self.creator) && _amount > 0);
        self.factory = Factory_Interface(self.factory_address);
        getVariables(self);
        self.contract_details[1] = self.contract_details[0].add(self.contract_details[3].mul(86400));
        assert(self.contract_details[1]-self.contract_details[0] < 28*86400);
        self.token_amount = _amount;
        self.token = ERC20_Interface(self.token_address);
        assert(self.token.balanceOf(address(this)) == SafeMath.mul(_amount,2));
        uint tokenratio = 1;
        (self.long_token_address,self.short_token_address,tokenratio) = self.factory.createToken(self.token_amount,self.creator,self.contract_details[0]);
        self.num_DRCT_tokens = self.token_amount.div(tokenratio);
        oracleQuery(self);
        emit SwapCreation(self.token_address,self.contract_details[0],self.contract_details[1],self.token_amount);
        self.current_state = SwapState.started;
    }

    /**
    *@dev Getter function for contract details saved in the SwapStorage struct
    */
    function getVariables(SwapStorage storage self) internal{
        (self.oracle_address,self.contract_details[3],self.contract_details[2],self.token_address) = self.factory.getVariables();
    }

    /**
    *@dev check if the oracle has been queried withing the last day 
    */
    function oracleQuery(SwapStorage storage self) internal returns(bool){
        Oracle_Interface oracle = Oracle_Interface(self.oracle_address);
        uint _today = now - (now % 86400);
        uint i;
        if(_today >= self.contract_details[0] && self.contract_details[4] == 0){
            for(i=0;i < (_today- self.contract_details[0])/86400;i++){
                if(oracle.getQuery(self.contract_details[0]+i*86400)){
                    self.contract_details[4] = oracle.retrieveData(self.contract_details[0]+i*86400);
                    return true;
                }
            }
            if(self.contract_details[4] ==0){
                oracle.pushData();
                return false;
            }
        }
        if(_today >= self.contract_details[1] && self.contract_details[5] == 0){
            for(i=0;i < (_today- self.contract_details[1])/86400;i++){
                if(oracle.getQuery(self.contract_details[1]+i*86400)){
                    self.contract_details[5] = oracle.retrieveData(self.contract_details[1]+i*86400);
                    return true;
                }
            }
            if(self.contract_details[5] ==0){
                oracle.pushData();
                return false;
            }
        }
        return true;
    }

    /**
    *@dev This function calculates the payout of the swap. It can be called after the Swap has been tokenized.
    *The value of the underlying cannot reach zero, but rather can only get within 0.001 * the precision
    *of the Oracle.
    */
    function Calculate(SwapStorage storage self) internal{
        uint ratio;
        self.token_amount = self.token_amount.mul(10000-self.contract_details[6]).div(10000);
        if (self.contract_details[4] > 0 && self.contract_details[5] > 0)
            ratio = (self.contract_details[5]).mul(100000).div(self.contract_details[4]);
            if (ratio > 100000){
                ratio = (self.contract_details[2].mul(ratio - 100000)).add(100000);
            }
            else if (ratio < 100000){
                    ratio = SafeMath.min(100000,(self.contract_details[2].mul(100000-ratio)));
                    ratio = 100000 - ratio;
            }
        else if (self.contract_details[5] > 0)
            ratio = 10e10;
        else if (self.contract_details[4] > 0)
            ratio = 0;
        else
            ratio = 100000;
        ratio = SafeMath.min(200000,ratio);
        self.pay_to_long = (ratio.mul(self.token_amount)).div(self.num_DRCT_tokens).div(100000);
        self.pay_to_short = (SafeMath.sub(200000,ratio).mul(self.token_amount)).div(self.num_DRCT_tokens).div(100000);
    }

    /**
    *@dev This function can be called after the swap is tokenized or after the Calculate function is called.
    *If the Calculate function has not yet been called, this function will call it.
    *The function then pays every token holder of both the long and short DRCT tokens
    *What should we do about zeroed out values? 
    */
    function forcePay(SwapStorage storage self,uint[2] _range) internal returns (bool) {
       //Calls the Calculate function first to calculate short and long shares
        require(self.current_state == SwapState.started && now >= self.contract_details[1]);
        bool ready = oracleQuery(self);
        if(ready){
            Calculate(self);
            //Loop through the owners of long and short DRCT tokens and pay them
            DRCT_Token_Interface drct = DRCT_Token_Interface(self.long_token_address);
            uint count = drct.addressCount(address(this));
            uint loop_count = count < _range[1] ? count : _range[1];
            //Indexing begins at 1 for DRCT_Token balances
            for(uint i = loop_count-1; i >= _range[0] ; i--) {
                address long_owner;
                uint to_pay_long;
                (to_pay_long, long_owner) = drct.getBalanceAndHolderByIndex(i, address(this));
                paySwap(self,long_owner, to_pay_long, true);
            }

            drct = DRCT_Token_Interface(self.short_token_address);
            count = drct.addressCount(address(this));
            loop_count = count < _range[1] ? count : _range[1];
            for(uint j = loop_count-1; j >= _range[0] ; j--) {
                address short_owner;
                uint to_pay_short;
                (to_pay_short, short_owner) = drct.getBalanceAndHolderByIndex(j, address(this));
                paySwap(self,short_owner, to_pay_short, false);
            }
            if (loop_count == count){
                self.token.transfer(self.factory_address, self.token.balanceOf(address(this)));
                emit PaidOut(self.pay_to_long,self.pay_to_short);
                self.current_state = SwapState.ended;
            }
        }
        return ready;
    }

    /**
    *This function pays the receiver an amount determined by the Calculate function
    *@param _receiver The recipient of the payout
    *@param _amount The amount of token the recipient holds
    *@param _is_long Whether or not the reciever holds a long or short token
    */
    function paySwap(SwapStorage storage self,address _receiver, uint _amount, bool _is_long) internal {
        if (_is_long) {
            if (self.pay_to_long > 0){
                self.token.transfer(_receiver, _amount.mul(self.pay_to_long));
                self.factory.payToken(_receiver,self.long_token_address);
            }
        } else {
            if (self.pay_to_short > 0){
                self.token.transfer(_receiver, _amount.mul(self.pay_to_short));
                self.factory.payToken(_receiver,self.short_token_address);
            }
        }
    }

    /**
    @dev Getter function for swap state
    */
    function showCurrentState(SwapStorage storage self)  internal view returns(uint) {
        return uint(self.current_state);
    }
    


}

contract TokenToTokenSwap {

    using TokenLibrary for TokenLibrary.SwapStorage;

    /*Variables*/
    TokenLibrary.SwapStorage public swap;

    /*Functions*/
    /**
    *@dev Constructor - Run by the factory at contract creation
    *@param _factory_address address of the factory that created this contract
    *@param _creator address of the person who created the contract
    *@param _userContract address of the _userContract that is authorized to interact with this contract
    *@param _start_date start date of the contract
    */
    constructor (address _factory_address, address _creator, address _userContract, uint _start_date) public {
        swap.startSwap(_factory_address,_creator,_userContract,_start_date);
    }
    
    function init (address _factory_address, address _creator, address _userContract, uint _start_date) public {
        swap.startSwap(_factory_address,_creator,_userContract,_start_date);
    }

     /**
    @dev A getter function for retriving standardized variables from the factory contract
    */
    function showPrivateVars() public view returns (address[5],uint, uint, uint, uint, uint){
        return swap.showPrivateVars();
    }

    /**
    @dev A getter function for retriving standardized variables from the factory contract
    */
    function currentState() public view returns(uint){
        return swap.showCurrentState();
    }

    /**
    *@dev Allows the sender to create the terms for the swap
    *@param _amount Amount of Token that should be deposited for the notional
    *@param _senderAdd States the owner of this side of the contract (does not have to be msg.sender)
    */
    function createSwap(uint _amount, address _senderAdd) public {
        swap.createSwap(_amount,_senderAdd);
    }

    /**
    *@dev This function can be called after the swap is tokenized or after the Calculate function is called.
    *If the Calculate function has not yet been called, this function will call it.
    *The function then pays every token holder of both the long and short DRCT tokens
    *@param _begin start date of swap
    *@param _end end date of swap
    */
    function forcePay(uint _begin, uint _end) public returns (bool) {
       swap.forcePay([_begin,_end]);
    }
}