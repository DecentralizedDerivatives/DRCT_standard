pragma solidity ^0.4.24;

//Swap Deployer functions - descriptions can be found in Deployer.sol
interface Deployer_Interface {
  function newContract(address _party, address user_contract, uint _start_date) external payable returns (address);
}

//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount(address _swap) external constant returns (uint);
  function getBalanceAndHolderByIndex(uint _ind, address _swap) external constant returns (uint, address);
  function getIndexByAddress(address _owner, address _swap) external constant returns (uint);
  function createToken(uint _supply, address _owner, address _swap) external;
  function getFactoryAddress() external view returns(address);
  function pay(address _party, address _swap) external;
  function partyCount(address _swap) external constant returns(uint);
}

//ERC20 function interface
interface ERC20_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
}

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) external returns (address,address, uint);
  function payToken(address _party, address _token_add) external;
  function deployContract(uint _start_date) external payable returns (address);
   function getBase() external view returns(address);
  function getVariables() external view returns (address, uint, uint, address,uint);
  function isWhitelisted(address _member) external view returns (bool);
}

interface Membership_Interface {
    function getMembershipType(address _member) external constant returns(uint);
}

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function getQuery(uint _date) external view returns(bool);
  function retrieveData(uint _date) external view returns (uint);
  function pushData() external payable;
}

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface TokenToTokenSwap_Interface {
  function createSwap(uint _amount, address _senderAdd) external;
}

//ERC20 function interface with create token and withdraw
interface Wrapped_Ether_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
  function withdraw(uint _value) external;
  function createToken() external;

}
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

/**
*The DRCTLibrary contains the reference code used in the DRCT_Token (an ERC20 compliant token
*representing the payout of the swap contract specified in the Factory contract).
*/
library DRCTLibrary{

    using SafeMath for uint256;

    /*Structs*/
    /**
    *@dev Keeps track of balance amounts in the balances array
    */
    struct Balance {
        address owner;
        uint amount;
        }

    struct TokenStorage{
        //This is the factory contract that the token is standardized at
        address factory_contract;
        //Total supply of outstanding tokens in the contract
        uint total_supply;
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
    }   

    /*Events*/
    /**
    *@dev events for transfer and approvals
    */
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event CreateToken(address _from, uint _value);
    
    /*Functions*/
    /**
    *@dev Constructor - sets values for token name and token supply, as well as the 
    *factory_contract, the swap.
    *@param _factory 
    */
    function startToken(TokenStorage storage self,address _factory) public {
        self.factory_contract = _factory;
    }

    /**
    *@dev ensures the member is whitelisted
    *@param _member is the member address that is chekced agaist the whitelist
    */
    function isWhitelisted(TokenStorage storage self,address _member) internal view returns(bool){
        Factory_Interface _factory = Factory_Interface(self.factory_contract);
        return _factory.isWhitelisted(_member);
    }

    /**
    *@dev gets the factory address
    */
    function getFactoryAddress(TokenStorage storage self) external view returns(address){
        return self.factory_contract;
    }

    /**
    *@dev Token Creator - This function is called by the factory contract and creates new tokens
    *for the user
    *@param _supply amount of DRCT tokens created by the factory contract for this swap
    *@param _owner address
    *@param _swap address
    */
    function createToken(TokenStorage storage self,uint _supply, address _owner, address _swap) public{
        require(msg.sender == self.factory_contract);
        //Update total supply of DRCT Tokens
        self.total_supply = self.total_supply.add(_supply);
        //Update the total balance of the owner
        self.user_total_balances[_owner] = self.user_total_balances[_owner].add(_supply);
        //If the user has not entered any swaps already, push a zeroed address to their user_swaps mapping to prevent default value conflicts in user_swaps_index
        if (self.user_swaps[_owner].length == 0)
            self.user_swaps[_owner].push(address(0x0));
        //Add a new swap index for the owner
        self.user_swaps_index[_owner][_swap] = self.user_swaps[_owner].length;
        //Push a new swap address to the owner's swaps
        self.user_swaps[_owner].push(_swap);
        //Push a zeroed Balance struct to the swap balances mapping to prevent default value conflicts in swap_balances_index
        self.swap_balances[_swap].push(Balance({
            owner: 0,
            amount: 0
        }));
        //Add a new owner balance index for the swap
        self.swap_balances_index[_swap][_owner] = 1;
        //Push the owner's balance to the swap
        self.swap_balances[_swap].push(Balance({
            owner: _owner,
            amount: _supply
        }));
        emit CreateToken(_owner,_supply);
    }

    /**
    *@dev Called by the factory contract, and pays out to a _party
    *@param _party being paid
    *@param _swap address
    */
    function pay(TokenStorage storage self,address _party, address _swap) public{
        require(msg.sender == self.factory_contract);
        uint party_balance_index = self.swap_balances_index[_swap][_party];
        require(party_balance_index > 0);
        uint party_swap_balance = self.swap_balances[_swap][party_balance_index].amount;
        //reduces the users totals balance by the amount in that swap
        self.user_total_balances[_party] = self.user_total_balances[_party].sub(party_swap_balance);
        //reduces the total supply by the amount of that users in that swap
        self.total_supply = self.total_supply.sub(party_swap_balance);
        //sets the partys balance to zero for that specific swaps party balances
        self.swap_balances[_swap][party_balance_index].amount = 0;
    }

    /**
    *@dev Returns the users total balance (sum of tokens in all swaps the user has tokens in)
    *@param _owner user address
    *@return user total balance
    */
    function balanceOf(TokenStorage storage self,address _owner) public constant returns (uint balance) {
       return self.user_total_balances[_owner]; 
     }

    /**
    *@dev Getter for the total_supply of tokens in the contract
    *@return total supply
    */
    function totalSupply(TokenStorage storage self) public constant returns (uint _total_supply) {
       return self.total_supply;
    }

    /**
    *@dev Removes the address from the swap balances for a swap, and moves the last address in the
    *swap into their place
    *@param _remove address of prevous owner
    *@param _swap address used to get last addrss of the swap to replace the removed address
    */
    function removeFromSwapBalances(TokenStorage storage self,address _remove, address _swap) internal {
        uint last_address_index = self.swap_balances[_swap].length.sub(1);
        address last_address = self.swap_balances[_swap][last_address_index].owner;
        //If the address we want to remove is the final address in the swap
        if (last_address != _remove) {
            uint remove_index = self.swap_balances_index[_swap][_remove];
            //Update the swap's balance index of the last address to that of the removed address index
            self.swap_balances_index[_swap][last_address] = remove_index;
            //Set the swap's Balance struct at the removed index to the Balance struct of the last address
            self.swap_balances[_swap][remove_index] = self.swap_balances[_swap][last_address_index];
        }
        //Remove the swap_balances index for this address
        delete self.swap_balances_index[_swap][_remove];
        //Finally, decrement the swap balances length
        self.swap_balances[_swap].length = self.swap_balances[_swap].length.sub(1);
    }

    /**
    *@dev This is the main function to update the mappings when a transfer happens
    *@param _from address to send funds from
    *@param _to address to send funds to
    *@param _amount amount of token to send
    */
    function transferHelper(TokenStorage storage self,address _from, address _to, uint _amount) internal {
        //Get memory copies of the swap arrays for the sender and reciever
        address[] memory from_swaps = self.user_swaps[_from];
        //Iterate over sender's swaps in reverse order until enough tokens have been transferred
        for (uint i = from_swaps.length.sub(1); i > 0; i--) {
            //Get the index of the sender's balance for the current swap
            uint from_swap_user_index = self.swap_balances_index[from_swaps[i]][_from];
            Balance memory from_user_bal = self.swap_balances[from_swaps[i]][from_swap_user_index];
            //If the current swap will be entirely depleted - we remove all references to it for the sender
            if (_amount >= from_user_bal.amount) {
                _amount -= from_user_bal.amount;
                //If this swap is to be removed, we know it is the (current) last swap in the user's user_swaps list, so we can simply decrement the length to remove it
                self.user_swaps[_from].length = self.user_swaps[_from].length.sub(1);
                //Remove the user swap index for this swap
                delete self.user_swaps_index[_from][from_swaps[i]];
                //If the _to address already holds tokens from this swap
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                    //Get the index of the _to balance in this swap
                    uint to_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                    assert(to_balance_index != 0);
                    //Add the _from tokens to _to
                    self.swap_balances[from_swaps[i]][to_balance_index].amount = self.swap_balances[from_swaps[i]][to_balance_index].amount.add(from_user_bal.amount);
                    //Remove the _from address from this swap's balance array
                    removeFromSwapBalances(self,_from, from_swaps[i]);
                } else {
                    //Prepare to add a new swap by assigning the swap an index for _to
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                //Add the new swap to _to
                self.user_swaps[_to].push(from_swaps[i]);
                //Give the reciever the sender's balance for this swap
                self.swap_balances[from_swaps[i]][from_swap_user_index].owner = _to;
                //Give the reciever the sender's swap balance index for this swap
                self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances_index[from_swaps[i]][_from];
                //Remove the swap balance index from the sending party
                delete self.swap_balances_index[from_swaps[i]][_from];
            }
            //If there is no more remaining to be removed, we break out of the loop
            if (_amount == 0)
                break;
            } else {
                //The amount in this swap is more than the amount we still need to transfer
                uint to_swap_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                //If the _to address already holds tokens from this swap
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                    //Because both addresses are in this swap, and neither will be removed, we simply update both swap balances
                    self.swap_balances[from_swaps[i]][to_swap_balance_index].amount = self.swap_balances[from_swaps[i]][to_swap_balance_index].amount.add(_amount);
                } else {
                    //Prepare to add a new swap by assigning the swap an index for _to
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                    self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                    //And push the new swap
                    self.user_swaps[_to].push(from_swaps[i]);
                    //_to is not in this swap, so we give this swap a new balance index for _to
                    self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances[from_swaps[i]].length;
                    //And push a new balance for _to
                    self.swap_balances[from_swaps[i]].push(Balance({
                        owner: _to,
                        amount: _amount
                    }));
                }
                //Finally, update the _from user's swap balance
                self.swap_balances[from_swaps[i]][from_swap_user_index].amount = self.swap_balances[from_swaps[i]][from_swap_user_index].amount.sub(_amount);
                //Because we have transferred the last of the amount to the reciever, we break;
                break;
            }
        }
    }

    /**
    *@dev ERC20 compliant transfer function
    *@param _to Address to send funds to
    *@param _amount Amount of token to send
    *@return true for successful
    */
    function transfer(TokenStorage storage self, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[msg.sender];
        if (
            _to == msg.sender ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount
        ) return false;
        transferHelper(self,msg.sender, _to, _amount);
        self.user_total_balances[msg.sender] = self.user_total_balances[msg.sender].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    /**
    *@dev ERC20 compliant transferFrom function
    *@param _from address to send funds from (must be allowed, see approve function)
    *@param _to address to send funds to
    *@param _amount amount of token to send
    *@return true for successful
    */
    function transferFrom(TokenStorage storage self, address _from, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[_from];
        uint sender_allowed = self.allowed[_from][msg.sender];
        if (
            _to == _from ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount ||
            sender_allowed < _amount
        ) return false;
        transferHelper(self,_from, _to, _amount);
        self.user_total_balances[_from] = self.user_total_balances[_from].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        self.allowed[_from][msg.sender] = self.allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    *@dev ERC20 compliant approve function
    *@param _spender party that msg.sender approves for transferring funds
    *@param _amount amount of token to approve for sending
    *@return true for successful
    */
    function approve(TokenStorage storage self, address _spender, uint _amount) public returns (bool) {
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *@dev Counts addresses involved in the swap based on the length of balances array for _swap
    *@param _swap address
    *@return the length of the balances array for the swap
    */
    function addressCount(TokenStorage storage self, address _swap) public constant returns (uint) { 
        return self.swap_balances[_swap].length; 
    }

    /**
    *@dev Gets the owner address and amount by specifying the swap address and index
    *@param _ind specified index in the swap
    *@param _swap specified swap address
    *@return the owner address associated with a particular index in a particular swap
    *@return the amount to transfer associated with a particular index in a particular swap
    */
    function getBalanceAndHolderByIndex(TokenStorage storage self, uint _ind, address _swap) public constant returns (uint, address) {
        return (self.swap_balances[_swap][_ind].amount, self.swap_balances[_swap][_ind].owner);
    }

    /**
    *@dev Gets the index by specifying the swap and owner addresses
    *@param _owner specifed address
    *@param _swap  specified swap address
    *@return the index associated with the _owner address in a particular swap
    */
    function getIndexByAddress(TokenStorage storage self, address _owner, address _swap) public constant returns (uint) {
        return self.swap_balances_index[_swap][_owner]; 
    }

    /**
    *@dev Look up how much the spender or contract is allowed to spend?
    *@param _owner 
    *@param _spender party approved for transfering funds 
    *@return the allowed amount _spender can spend of _owner's balance
    */
    function allowance(TokenStorage storage self, address _owner, address _spender) public constant returns (uint) {
        return self.allowed[_owner][_spender]; 
    }
}

/**
*The TokenLibrary contains the reference code used to create the specific DRCT base contract 
*that holds the funds of the contract and redistributes them based upon the change in the
*underlying values
*/

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
        uint[8] contract_details;
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
    *@dev Acts the constructor function in the cloned swap
    *@param _factory_address
    *@param _creator address of swap creator
    *@param _userContract address
    *@param _start_date swap start date
    */
    function startSwap (SwapStorage storage self, address _factory_address, address _creator, address _userContract, uint _start_date) internal {
        require(self.creator == address(0));
        self.creator = _creator;
        self.factory_address = _factory_address;
        self.userContract = _userContract;
        self.contract_details[0] = _start_date;
        self.current_state = SwapState.created;
        self.contract_details[7] = 0;
    }

    /**
    *@dev A getter function for retriving standardized variables from the factory contract
    *@return 
    *[userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens, , multiplier, duration, Start date, end_date
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
        emit SwapCreation(self.token_address,self.contract_details[0],self.contract_details[1],self.token_amount);
        self.current_state = SwapState.started;
    }

    /**
    *@dev Getter function for contract details saved in the SwapStorage struct
    *Gets the oracle address, duration, multiplier, base token address, and fee
    *and from the Factory.getVariables function.
    */
    function getVariables(SwapStorage storage self) internal{
        (self.oracle_address,self.contract_details[3],self.contract_details[2],self.token_address,self.contract_details[6]) = self.factory.getVariables();
    }

    /**
    *@dev check if the oracle has been queried within the last day 
    *@return true if it was queried and the start and end values are not zero
    *and false if they are.
    */
    function oracleQuery(SwapStorage storage self) internal returns(bool){
        Oracle_Interface oracle = Oracle_Interface(self.oracle_address);
        uint _today = now - (now % 86400);
        uint i = 0;
        if(_today >= self.contract_details[0]){
            while(i < (_today- self.contract_details[0])/86400 && self.contract_details[4] == 0){
                if(oracle.getQuery(self.contract_details[0]+i*86400)){
                    self.contract_details[4] = oracle.retrieveData(self.contract_details[0]+i*86400);
                }
                i++;
            }
        }
        i = 0;
        if(_today >= self.contract_details[1]){
            while(i < (_today- self.contract_details[1])/86400 && self.contract_details[5] == 0){
                if(oracle.getQuery(self.contract_details[1]+i*86400)){
                    self.contract_details[5] = oracle.retrieveData(self.contract_details[1]+i*86400);
                }
                i++;
            }
        }
        if(self.contract_details[4] != 0 && self.contract_details[5] != 0){
            return true;
        }
        else{
            return false;
        }
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
    *@param _numtopay number of contracts to try and pay (run it again if its not enough)
    *@return true if the oracle was called and all contracts are paid or false ?
    */
    function forcePay(SwapStorage storage self,uint _numtopay) internal returns (bool) {
       //Calls the Calculate function first to calculate short and long shares
        require(self.current_state == SwapState.started && now >= self.contract_details[1]);
        bool ready = oracleQuery(self);
        if(ready){
            Calculate(self);
            //Loop through the owners of long and short DRCT tokens and pay them
            DRCT_Token_Interface drct = DRCT_Token_Interface(self.long_token_address);
            uint[6] memory counts;
            address token_owner;
            counts[0] = drct.addressCount(address(this));
            counts[1] = counts[0] <= self.contract_details[7].add(_numtopay) ? counts[0] : self.contract_details[7].add(_numtopay).add(1);
            //Indexing begins at 1 for DRCT_Token balances
            if(self.contract_details[7] < counts[1]){
                for(uint i = counts[1]-1; i > self.contract_details[7] ; i--) {
                    (counts[4], token_owner) = drct.getBalanceAndHolderByIndex(i, address(this));
                    paySwap(self,token_owner,counts[4], true);
                }
            }

            drct = DRCT_Token_Interface(self.short_token_address);
            counts[2] = drct.addressCount(address(this));
            counts[3] = counts[2] <= self.contract_details[7].add(_numtopay) ? counts[2] : self.contract_details[7].add(_numtopay).add(1);
            if(self.contract_details[7] < counts[3]){
                for(uint j = counts[3]-1; j > self.contract_details[7] ; j--) {
                    (counts[5], token_owner) = drct.getBalanceAndHolderByIndex(j, address(this));
                    paySwap(self,token_owner,counts[5], false);
                }
            }
            if (counts[0] == counts[1] && counts[2] == counts[3]){
                self.token.transfer(self.factory_address, self.token.balanceOf(address(this)));
                emit PaidOut(self.pay_to_long,self.pay_to_short);
                self.current_state = SwapState.ended;
            }
            self.contract_details[7] = self.contract_details[7].add(_numtopay);
        }
        return ready;
    }

    /**
    *This function pays the receiver an amount determined by the Calculate function
    *@param _receiver is the recipient of the payout
    *@param _amount is the amount of token the recipient holds
    *@param _is_long is true if the reciever holds a long token
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
    *@dev Getter function for swap state
    *@return current state of swap
    */
    function showCurrentState(SwapStorage storage self)  internal view returns(uint) {
        return uint(self.current_state);
    }
    
}

/**
*This contracts helps clone factories and swaps through the Deployer.sol and MasterDeployer.sol.
*The address of the targeted contract to clone has to be provided.
*/
contract CloneFactory {

    /*Variables*/
    address internal owner;
    
    /*Events*/
    event CloneCreated(address indexed target, address clone);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }    
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _owner the new owner address
    */
    function setOwner(address _owner) public onlyOwner(){
        owner = _owner;
    }

    /**
    *@dev Creates factory clone
    *@param _target is the address being cloned
    *@return address for clone
    */
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




/**
*This contract is the specific DRCT base contract that holds the funds of the contract and
*redistributes them based upon the change in the underlying values
*/

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
    
    /**
    *@dev Acts as a constructor when cloning the swap
    *@param _factory_address address of the factory that created this contract
    *@param _creator address of the person who created the contract
    *@param _userContract address of the _userContract that is authorized to interact with this contract
    *@param _start_date start date of the contract
    */
    function init (address _factory_address, address _creator, address _userContract, uint _start_date) public {
        swap.startSwap(_factory_address,_creator,_userContract,_start_date);
    }

    /**
    *@dev A getter function for retriving standardized variables from the factory contract
    *@return 
    *[userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens, , multiplier, duration, Start date, end_date
    */
    function showPrivateVars() public view returns (address[5],uint, uint, uint, uint, uint){
        return swap.showPrivateVars();
    }

    /**
    *@dev A getter function for retriving current swap state from the factory contract
    *@return current state (References swapState Enum: 1=created, 2=started, 3=ended)
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
    *@param _topay number of contracts to try and pay (run it again if its not enough)
    *@return true if the oracle was called and all contracts were paid out or false once ?
    */
    function forcePay(uint _topay) public returns (bool) {
       swap.forcePay(_topay);
    }


}


/**
*Swap Deployer Contract - purpose is to save gas for deployment of Factory contract.
*It ensures only the factory can create new contracts and uses CloneFactory to clone 
*the swap specified.
*/

contract Deployer is CloneFactory {
    /*Variables*/
    address internal factory;
    address public swap;
    
    /*Events*/
    event Deployed(address indexed master, address indexed clone);

    /*Functions*/
    /**
    *@dev Deploys the factory contract and swap address
    *@param _factory is the address of the factory contract
    */    
    constructor(address _factory) public {
        factory = _factory;
        swap = new TokenToTokenSwap(address(this),msg.sender,address(this),now);
    }

    /**
    *@dev Set swap address to clone
    *@param _addr swap address to clone
    */
    function updateSwap(address _addr) public onlyOwner() {
        swap = _addr;
    }
        
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
        TokenToTokenSwap(new_swap).init(factory, _party, _user, _start);
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

/**
*The DRCT_Token is an ERC20 compliant token representing the payout of the swap contract
*specified in the Factory contract.
*Each Factory contract is specified one DRCT Token and the token address can contain many
*different swap contracts that are standardized at the Factory level.
*The logic for the functions in this contract is housed in the DRCTLibary.sol.
*/
contract DRCT_Token {

    using DRCTLibrary for DRCTLibrary.TokenStorage;

    /*Variables*/
    DRCTLibrary.TokenStorage public drct;

    /*Functions*/
    /**
    *@dev Constructor - sets values for token name and token supply, as well as the 
    *factory_contract, the swap.
    *@param _factory 
    */
    constructor() public {
        drct.startToken(msg.sender);
    }

    /**
    *@dev Token Creator - This function is called by the factory contract and creates new tokens
    *for the user
    *@param _supply amount of DRCT tokens created by the factory contract for this swap
    *@param _owner address
    *@param _swap address
    */
    function createToken(uint _supply, address _owner, address _swap) public{
        drct.createToken(_supply,_owner,_swap);
    }

    /**
    *@dev gets the factory address
    */
    function getFactoryAddress() external view returns(address){
        return drct.getFactoryAddress();
    }

    /**
    *@dev Called by the factory contract, and pays out to a _party
    *@param _party being paid
    *@param _swap address
    */
    function pay(address _party, address _swap) public{
        drct.pay(_party,_swap);
    }

    /**
    *@dev Returns the users total balance (sum of tokens in all swaps the user has tokens in)
    *@param _owner user address
    *@return user total balance
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
       return drct.balanceOf(_owner);
     }

    /**
    *@dev Getter for the total_supply of tokens in the contract
    *@return total supply
    */
    function totalSupply() public constant returns (uint _total_supply) {
       return drct.totalSupply();
    }

    /**
    *ERC20 compliant transfer function
    *@param _to Address to send funds to
    *@param _amount Amount of token to send
    *@return true for successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        return drct.transfer(_to,_amount);
    }

    /**
    *@dev ERC20 compliant transferFrom function
    *@param _from address to send funds from (must be allowed, see approve function)
    *@param _to address to send funds to
    *@param _amount amount of token to send
    *@return true for successful transfer
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        return drct.transferFrom(_from,_to,_amount);
    }

    /**
    *@dev ERC20 compliant approve function
    *@param _spender party that msg.sender approves for transferring funds
    *@param _amount amount of token to approve for sending
    *@return true for successful
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        return drct.approve(_spender,_amount);
    }

    /**
    *@dev Counts addresses involved in the swap based on the length of balances array for _swap
    *@param _swap address
    *@return the length of the balances array for the swap
    */
    function addressCount(address _swap) public constant returns (uint) { 
        return drct.addressCount(_swap); 
    }

    /**
    *@dev Gets the owner address and amount by specifying the swap address and index
    *@param _ind specified index in the swap
    *@param _swap specified swap address
    *@return the amount to transfer associated with a particular index in a particular swap
    *@return the owner address associated with a particular index in a particular swap
    */
    function getBalanceAndHolderByIndex(uint _ind, address _swap) public constant returns (uint, address) {
        return drct.getBalanceAndHolderByIndex(_ind,_swap);
    }

    /**
    *@dev Gets the index by specifying the swap and owner addresses
    *@param _owner specifed address
    *@param _swap  specified swap address
    *@return the index associated with the _owner address in a particular swap
    */
    function getIndexByAddress(address _owner, address _swap) public constant returns (uint) {
        return drct.getIndexByAddress(_owner,_swap); 
    }

    /**
    *@dev Look up how much the spender or contract is allowed to spend?
    *@param _owner address
    *@param _spender party approved for transfering funds 
    *@return the allowed amount _spender can spend of _owner's balance
    */
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return drct.allowance(_owner,_spender); 
    }
}

/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    
    /*Structs*/
    //This is the base data structure for an order (the maker of the order and the price)
    struct Order {
        address maker;// the placer of the order
        uint price;// The price in wei
        uint amount;
        address asset;
    }

    struct ListAsset {
        uint price;
        uint amount;
    }

    mapping(address => ListAsset) public listOfAssets;
    //Maps an OrderID to the list of orders
    mapping(uint256 => Order) public orders;
    //An mapping of a token address to the orderID's
    mapping(address =>  uint256[]) public forSale;
    //Index telling where a specific tokenId is in the forSale array
    mapping(uint256 => uint256) internal forSaleIndex;
    //Index telling where a specific tokenId is in the forSale array
    address[] public openBooks;
    //mapping of address to position in openBooks
    mapping (address => uint) internal openBookIndex;
    //mapping of user to their orders
    mapping(address => uint[]) public userOrders;
    //mapping from orderId to userOrder position
    mapping(uint => uint) internal userOrderIndex;
    //A list of the blacklisted addresses
    mapping(address => bool) internal blacklist;
    //order_nonce;
    uint internal order_nonce;

    /*Events*/
    event OrderPlaced(address _sender,address _token, uint256 _amount, uint256 _price);
    event Sale(address _sender,address _token, uint256 _amount, uint256 _price);
    event OrderRemoved(address _sender,address _token, uint256 _amount, uint256 _price);

    /*Modifiers*/
    /**
    *@dev Access modifier for Owner functionality
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev the constructor argument to set the owner and initialize the array.
    */
    constructor() public{
        owner = msg.sender;
        openBooks.push(address(0));
        order_nonce = 1;
    }

    /**
    *@dev list allows a party to place an order on the orderbook
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require(blacklist[msg.sender] == false);
        require(_price > 0);
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(token.allowance(msg.sender,address(this)) >= _amount);
        if(forSale[_tokenadd].length == 0){
            forSale[_tokenadd].push(0);
            }
        forSaleIndex[order_nonce] = forSale[_tokenadd].length;
        forSale[_tokenadd].push(order_nonce);
        orders[order_nonce] = Order({
            maker: msg.sender,
            asset: _tokenadd,
            price: _price,
            amount:_amount
        });
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
        if(openBookIndex[_tokenadd] == 0 ){    
            openBookIndex[_tokenadd] = openBooks.length;
            openBooks.push(_tokenadd);
        }
        userOrderIndex[order_nonce] = userOrders[msg.sender].length;
        userOrders[msg.sender].push(order_nonce);
        order_nonce += 1;
    }

    /**
    *@dev list allows a party to list an order on the orderbook
    *@param _asset address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price per unit in wei
    */
    //Then you would have a mapping from an asset to its price/ quantity when you list it.
    function listDda(address _asset, uint256 _amount, uint256 _price) public onlyOwner() {
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        listing.price = _price;
        listing.amount= _amount;
    }

    /**
    *@dev buy allows a party to partially fill an order
    *@param _asset is the address of the assset listed
    *@param _amount is the amount of tokens to buy
    */
    function buyPerUnit(address _asset, uint256 _amount) external payable {
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        require(_amount <= listing.amount);
        require(msg.value == _amount.mul(listing.price));
        listing.amount= listing.amount.sub(_amount);
    }

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
    function unlist(uint256 _orderId) external{
        require(forSaleIndex[_orderId] > 0);
        Order memory _order = orders[_orderId];
        require(msg.sender== _order.maker || msg.sender == owner);
        unLister(_orderId,_order);
        emit OrderRemoved(msg.sender,_order.asset,_order.amount,_order.price);
    }

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
        Order memory _order = orders[_orderId];
        require(_order.price != 0 && _order.maker != address(0) && _order.asset != address(0) && _order.amount != 0);
        require(msg.value == _order.price);
        require(blacklist[msg.sender] == false);
        address maker = _order.maker;
        ERC20_Interface token = ERC20_Interface(_order.asset);
        if(token.allowance(_order.maker,address(this)) >= _order.amount){
            assert(token.transferFrom(_order.maker,msg.sender, _order.amount));
            maker.transfer(_order.price);
        }
        unLister(_orderId,_order);
        emit Sale(msg.sender,_order.asset,_order.amount,_order.price);
    }

    /**
    *@dev getOrder lists the price,amount, and maker of a specific token for a sale
    *@param _orderId uint256 ID of order
    *@return address of the party selling
    *@return uint of the price of the sale (in wei)
    *@return uint of the order amount of the sale
    *@return address of the token
    */
    function getOrder(uint256 _orderId) external view returns(address,uint,uint,address){
        Order storage _order = orders[_orderId];
        return (_order.maker,_order.price,_order.amount,_order.asset);
    }

    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    }

    /**
    *@notice This allows the owner to stop a malicious party from spamming the orderbook
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    */
    function blacklistParty(address _address, bool _motion) public onlyOwner() {
        blacklist[_address] = _motion;
    }

    /**
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool true for is blacklisted
    */
    function isBlacklist(address _address) public view returns(bool) {
        return blacklist[_address];
    }

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
    function getOrderCount(address _token) public constant returns(uint) {
        return forSale[_token].length;
    }

    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
    function getBookCount() public constant returns(uint) {
        return openBooks.length;
    }

    /**
    *@dev getOrders allows parties to get an array of all orderId's open for a given token
    *@param _token address of the drct token
    *@return _uint[] an array of the orders in the orderbook
    */
    function getOrders(address _token) public constant returns(uint[]) {
        return forSale[_token];
    }

    /**
    *@dev getUserOrders allows parties to get an array of all orderId's open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
    function getUserOrders(address _user) public constant returns(uint[]) {
        return userOrders[_user];
    }

    /**
    *@dev An internal function to update mappings when an order is removed from the book
    *@param _orderId is the uint256 ID of order
    *@param _order is the struct containing the details of the order
    */
    function unLister(uint256 _orderId, Order _order) internal{
            uint256 tokenIndex;
            uint256 lastTokenIndex;
            address lastAdd;
            uint256  lastToken;
        if(forSale[_order.asset].length == 2){
            tokenIndex = openBookIndex[_order.asset];
            lastTokenIndex = openBooks.length.sub(1);
            lastAdd = openBooks[lastTokenIndex];
            openBooks[tokenIndex] = lastAdd;
            openBookIndex[lastAdd] = tokenIndex;
            openBooks.length--;
            openBookIndex[_order.asset] = 0;
            forSale[_order.asset].length -= 2;
        }
        else{
            tokenIndex = forSaleIndex[_orderId];
            lastTokenIndex = forSale[_order.asset].length.sub(1);
            lastToken = forSale[_order.asset][lastTokenIndex];
            forSale[_order.asset][tokenIndex] = lastToken;
            forSaleIndex[lastToken] = tokenIndex;
            forSale[_order.asset].length--;
        }
        forSaleIndex[_orderId] = 0;
        orders[_orderId] = Order({
            maker: address(0),
            price: 0,
            amount:0,
            asset: address(0)
        });
        if(userOrders[_order.maker].length > 1){
            tokenIndex = userOrderIndex[_orderId];
            lastTokenIndex = userOrders[_order.maker].length.sub(1);
            lastToken = userOrders[_order.maker][lastTokenIndex];
            userOrders[_order.maker][tokenIndex] = lastToken;
            userOrderIndex[lastToken] = tokenIndex;
        }
        userOrders[_order.maker].length--;
        userOrderIndex[_orderId] = 0;
    }
}

/**
*The Factory contract sets the standardized variables and also deploys new contracts based on
*these variables for the user.  
*/
contract Factory {
    using SafeMath for uint256;
    
    /*Variables*/
    //Addresses of the Factory owner and oracle. For oracle information, 
    //check www.github.com/DecentralizedDerivatives/Oracles
    address public owner;
    address public oracle_address;
    //Address of the user contract
    address public user_contract;
    //Address of the deployer contract
    address internal deployer_address;
    Deployer_Interface internal deployer;
    address public token;
    //A fee for creating a swap in wei.  Plan is for this to be zero, however can be raised to prevent spam
    uint public fee;
    //swap fee
    uint public swapFee;
    //Duration of swap contract in days
    uint public duration;
    //Multiplier of reference rate.  2x refers to a 50% move generating a 100% move in the contract payout values
    uint public multiplier;
    //Token_ratio refers to the number of DRCT Tokens a party will get based on the number of base tokens.  As an example, 1e15 indicates that a party will get 1000 DRCT Tokens based upon 1 ether of wrapped wei. 
    uint public token_ratio;
    //Array of deployed contracts
    address[] public contracts;
    uint[] public startDates;
    address public memberContract;
    mapping(uint => bool) whitelistedTypes;
    mapping(address => uint) public created_contracts;
    mapping(address => uint) public token_dates;
    mapping(uint => address) public long_tokens;
    mapping(uint => address) public short_tokens;
    mapping(address => uint) public token_type; //1=short 2=long

    /*Events*/
    //Emitted when a Swap is created
    event ContractCreation(address _sender, address _created);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
     constructor() public {
        owner = msg.sender;
    }

    /**
    *@dev constructor function for cloned factory
    */
    function init(address _owner) public{
        require(owner == address(0));
        owner = _owner;
    }

    /**
    *@dev Sets the Membership contract address
    *@param _memberContract The new membership address
    */
    function setMemberContract(address _memberContract) public onlyOwner() {
        memberContract = _memberContract;
    }

    /**
    *@dev Sets the member types/permissions for those whitelisted
    *@param _memberTypes is the list of member types
    */
    function setWhitelistedMemberTypes(uint[] _memberTypes) public onlyOwner(){
        whitelistedTypes[0] = false;
        for(uint i = 0; i<_memberTypes.length;i++){
            whitelistedTypes[_memberTypes[i]] = true;
        }
    }

    /**
    *@dev Checks the membership type/permissions for whitelisted members
    *@param _member address to get membership type from
    */
    function isWhitelisted(address _member) public view returns (bool){
        Membership_Interface Member = Membership_Interface(memberContract);
        return whitelistedTypes[Member.getMembershipType(_member)];
    }
 
    /**
    *@dev Gets long and short token addresses based on specified date
    *@param _date 
    *@return short and long tokens' addresses
    */
    function getTokens(uint _date) public view returns(address, address){
        return(long_tokens[_date],short_tokens[_date]);
    }

    /**
    *@dev Gets the type of Token (long and short token) for the specifed 
    *token address
    *@param _token address 
    *@return token type short = 1 and long = 2
    */
    function getTokenType(address _token) public view returns(uint){
        return(token_type[_token]);
    }

    /**
    *@dev Updates the fee amount
    *@param _fee is the new fee amount
    */
    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

    /**
    *@dev Updates the swap fee amount
    *@param _swapFee is the new swap fee amount
    */
    function setSwapFee(uint _swapFee) public onlyOwner() {
        swapFee = _swapFee;
    }   

    /**
    *@dev Sets the deployer address
    *@param _deployer is the new deployer address
    */
    function setDeployer(address _deployer) public onlyOwner() {
        deployer_address = _deployer;
        deployer = Deployer_Interface(_deployer);
    }

    /**
    *@dev Sets the user_contract address
    *@param _userContract is the new userContract address
    */
    function setUserContract(address _userContract) public onlyOwner() {
        user_contract = _userContract;
    }

    /**
    *@dev Sets token ratio, swap duration, and multiplier variables for a swap.
    *@param _token_ratio the ratio of the tokens
    *@param _duration the duration of the swap, in days
    *@param _multiplier the multiplier used for the swap
    *@param _swapFee the swap fee
    */
    function setVariables(uint _token_ratio, uint _duration, uint _multiplier, uint _swapFee) public onlyOwner() {
        require(_swapFee < 10000);
        token_ratio = _token_ratio;
        duration = _duration;
        multiplier = _multiplier;
        swapFee = _swapFee;
    }

    /**
    *@dev Sets the address of the base tokens used for the swap
    *@param _token The address of a token to be used  as collateral
    */
    function setBaseToken(address _token) public onlyOwner() {
        token = _token;
    }

    /**
    *@dev Allows a user to deploy a new swap contract, if they pay the fee
    *@param _start_date the contract start date 
    *@return new_contract address for he newly created swap address and calls 
    *event 'ContractCreation'
    */
    function deployContract(uint _start_date) public payable returns (address) {
        require(msg.value >= fee && isWhitelisted(msg.sender));
        require(_start_date % 86400 == 0);
        address new_contract = deployer.newContract(msg.sender, user_contract, _start_date);
        contracts.push(new_contract);
        created_contracts[new_contract] = _start_date;
        emit ContractCreation(msg.sender,new_contract);
        return new_contract;
    }

    /**
    *@dev Deploys DRCT tokens for given start date
    *@param _start_date of contract
    */
    function deployTokenContract(uint _start_date) public{
        address _token;
        require(_start_date % 86400 == 0);
        require(long_tokens[_start_date] == address(0) && short_tokens[_start_date] == address(0));
        _token = new DRCT_Token();
        token_dates[_token] = _start_date;
        long_tokens[_start_date] = _token;
        token_type[_token]=2;
        _token = new DRCT_Token();
        token_type[_token]=1;
        short_tokens[_start_date] = _token;
        token_dates[_token] = _start_date;
        startDates.push(_start_date);

    }

    /**
    *@dev Deploys new tokens on a DRCT_Token contract -- called from within a swap
    *@param _supply The number of tokens to create
    *@param _party the address to send the tokens to
    *@param _start_date the start date of the contract      
    *@returns ltoken the address of the created DRCT long tokens
    *@returns stoken the address of the created DRCT short tokens
    *@returns token_ratio The ratio of the created DRCT token
    */
    function createToken(uint _supply, address _party, uint _start_date) public returns (address, address, uint) {
        require(created_contracts[msg.sender] == _start_date);
        address ltoken = long_tokens[_start_date];
        address stoken = short_tokens[_start_date];
        require(ltoken != address(0) && stoken != address(0));
            DRCT_Token drct_interface = DRCT_Token(ltoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
            drct_interface = DRCT_Token(stoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
        return (ltoken, stoken, token_ratio);
    }
  
    /**
    *@dev Allows the owner to set a new oracle address
    *@param _new_oracle_address 
    */
    function setOracleAddress(address _new_oracle_address) public onlyOwner() {
        oracle_address = _new_oracle_address; 
    }

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Allows the owner to pull contract creation fees
    *@return the withdrawal fee _val and the balance where is the return function?
    */
    function withdrawFees() public onlyOwner(){
        Wrapped_Ether_Interface token_interface = Wrapped_Ether_Interface(token);
        uint _val = token_interface.balanceOf(address(this));
        if(_val > 0){
            token_interface.withdraw(_val);
        }
        owner.transfer(address(this).balance);
     }

    /**
    *@dev fallback function
    */ 
    function() public payable {
    }

    /**
    *@dev Returns a tuple of many private variables.
    *The variables from this function are pass through to the TokenLibrary.getVariables function
    *@returns oracle_adress is the address of the oracle
    *@returns duration is the duration of the swap
    *@returns multiplier is the multiplier for the swap
    *@returns token is the address of token
    *@returns _swapFee is the swap fee 
    */
    function getVariables() public view returns (address, uint, uint, address,uint){
        return (oracle_address,duration, multiplier, token,swapFee);
    }

    /**
    *@dev Pays out to a DRCT token
    *@param _party is the address being paid
    *@param _token_add token to pay out
    */
    function payToken(address _party, address _token_add) public {
        require(created_contracts[msg.sender] > 0);
        DRCT_Token drct_interface = DRCT_Token(_token_add);
        drct_interface.pay(_party, msg.sender);
    }

    /**
    *@dev Counts number of contacts created by this factory
    *@return the number of contracts
    */
    function getCount() public constant returns(uint) {
        return contracts.length;
    }

    /**
    *@dev Counts number of start dates in this factory
    *@return the number of active start dates
    */
    function getDateCount() public constant returns(uint) {
        return startDates.length;
    }
}

/**
*This contract deploys a factory contract and uses CloneFactory to clone the factory
*specified.
*/

contract MasterDeployer is CloneFactory{
    
    using SafeMath for uint256;

    /*Variables*/
  address[] factory_contracts;
  address private factory;
  mapping(address => uint) public factory_index;

    /*Events*/
  event NewFactory(address _factory);

    /*Functions*/
    /**
    *@dev Initiates the factory_contract array with address(0)
    */
  constructor() public {
    factory_contracts.push(address(0));
  }

    /**
    *@dev Set factory address to clone
    *@param _factory address to clone
    */  
  function setFactory(address _factory) public onlyOwner(){
    factory = _factory;
  }

    /**
    *@dev creates a new factory by cloning the factory specified in setFactory.
    *@return _new_fac which is the new factory address
    */
  function deployFactory() public onlyOwner() returns(address){
    address _new_fac = createClone(factory);
    factory_index[_new_fac] = factory_contracts.length;
    factory_contracts.push(_new_fac);
    Factory(_new_fac).init(msg.sender);
    emit NewFactory(_new_fac);
    return _new_fac;
  }

    /**
    *@dev Removes the factory specified
    *@param _factory address to remove
    */
  function removeFactory(address _factory) public onlyOwner(){
    require(_factory != address(0) && factory_index[_factory] != 0);
    uint256 fIndex = factory_index[_factory];
        uint256 lastFactoryIndex = factory_contracts.length.sub(1);
        address lastFactory = factory_contracts[lastFactoryIndex];
        factory_contracts[fIndex] = lastFactory;
        factory_index[lastFactory] = fIndex;
        factory_contracts.length--;
        factory_index[_factory] = 0;
  }

    /**
    *@dev Counts the number of factories
    *@returns the number of active factories
    */
  function getFactoryCount() public constant returns(uint){
    return factory_contracts.length - 1;
  }

    /**
    *@dev Returns the factory address for the specified index
    *@param _index for factory to look up in the factory_contracts array
    *@return factory address for the index specified
    */
  function getFactorybyIndex(uint _index) public constant returns(address){
    return factory_contracts[_index];
  }
}

/**
*This contract allows users to sign up for the DDA Cooperative Membership.
*To complete membership DDA will provide instructions to complete KYC/AML verification
*through a system external to this contract.
*/
contract Membership {
    using SafeMath for uint256;
    
    /*Variables*/
    address public owner;
    //Memebership fees
    uint public memberFee;

    /*Structs*/
    /**
    *@dev Keeps member information 
    */
    struct Member {
        uint memberId;
        uint membershipType;
    }
    
    /*Mappings*/
    //Members information
    mapping(address => Member) public members;
    address[] public membersAccts;

    /*Events*/
    event UpdateMemberAddress(address _from, address _to);
    event NewMember(address _address, uint _memberId, uint _membershipType);
    event Refund(address _address, uint _amount);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
     constructor() public {
        owner = msg.sender;
    }

    /*
    *@dev Updates the fee amount
    *@param _memberFee fee amount for member
    */
    function setFee(uint _memberFee) public onlyOwner() {
        //define fee structure for the three membership types
        memberFee = _memberFee;
    }
    
    /**
    *@notice Allows a user to become DDA members if they pay the fee. However, they still have to complete
    *complete KYC/AML verification off line
    *@dev This creates and transfers the token to the msg.sender
    */
    function requestMembership() public payable {
        Member storage sender = members[msg.sender];
        require(msg.value >= memberFee && sender.membershipType == 0 );
        membersAccts.push(msg.sender);
        sender.memberId = membersAccts.length;
        sender.membershipType = 1;
        emit NewMember(msg.sender, sender.memberId, sender.membershipType);
    }
    
    /**
    *@dev This updates/transfers the member address 
    *@param _from is the current member address
    *@param _to is the address the member would like to update their current address with
    */
    function updateMemberAddress(address _from, address _to) public onlyOwner {
        require(_to != address(0));
        Member storage currentAddress = members[_from];
        Member storage newAddress = members[_to];
        require(newAddress.memberId == 0);
        newAddress.memberId = currentAddress.memberId;
        newAddress.membershipType = currentAddress.membershipType;
    membersAccts[currentAddress.memberId - 1] = _to;
        currentAddress.memberId = 0;
        currentAddress.membershipType = 0;
        emit UpdateMemberAddress(_from, _to);
    }

    /**
    *@dev Use this function to set membershipType for the member
    *@param _memberAddress address of member that we need to update membershipType
    *@param _membershipType type of membership to assign to member
    */
    function setMembershipType(address _memberAddress,  uint _membershipType) public onlyOwner{
        Member storage memberAddress = members[_memberAddress];
        memberAddress.membershipType = _membershipType;
    }

    /**
    *@dev getter function to get all membersAccts
    */
    function getMembers() view public returns (address[]){
        return membersAccts;
    }
    
    /**
    *@dev Get member information
    *@param _memberAddress address to pull the memberId, membershipType and membership
    */
    function getMember(address _memberAddress) view public returns(uint, uint) {
        return(members[_memberAddress].memberId, members[_memberAddress].membershipType);
    }

    /**
    *@dev Gets length of array containing all member accounts or total supply
    */
    function countMembers() view public returns(uint) {
        return membersAccts.length;
    }

    /**
    *@dev Gets membership type
    *@param _memberAddress address to view the membershipType
    */
    function getMembershipType(address _memberAddress) public constant returns(uint){
        return members[_memberAddress].membershipType;
    }
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Refund money if KYC/AML fails
    *@param _to address to send refund
    *@param _amount to refund. If no amount  is specified the current memberFee is refunded
    */
    function refund(address _to, uint _amount) public onlyOwner {
        require (_to != address(0));
        if (_amount == 0) {_amount = memberFee;}
        Member storage currentAddress = members[_to];
        membersAccts[currentAddress.memberId-1] = 0;
        currentAddress.memberId = 0;
        currentAddress.membershipType = 0;
        _to.transfer(_amount);
        emit Refund(_to, _amount);
    }

    /**
    *@dev Allow owner to withdraw funds
    *@param _to address to send funds
    *@param _amount to send
    */
    function withdraw(address _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }    
}

// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
    function randomDS_getSessionPubKeyHash() returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0)) oraclize_setNetwork(networkID_auto);
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) {
    }
    
    function oraclize_useCoupon(string code) oraclizeAPI internal {
        oraclize.useCoupon(code);
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }
    
    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];       
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    
    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    
    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];       
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    
    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    
    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
    }
    
    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
    
    function stra2cbor(string[] arr) internal returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there's a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }

    function ba2cbor(bytes[] arr) internal returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there's a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }
        
        
    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }
    
    function oraclize_getNetworkName() internal returns (string) {
        return oraclize_network_name;
    }
    
    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        if ((_nbytes == 0)||(_nbytes > 32)) throw;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes[3] memory args = [unonce, nbytes, sessionKeyHash]; 
        bytes32 queryId = oraclize_query(_delay, "random", args, _customGasLimit);
        oraclize_randomDS_setCommitment(queryId, sha3(bytes8(_delay), args[1], sha256(args[0]), args[2]));
        return queryId;
    }
    
    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }
    
    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;
        
        bytes32 sigr;
        bytes32 sigs;
        
        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        
        
        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(sha3(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(sha3(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;
        
        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);
        
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);
        
        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = 1; //role
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        
        if (sigok == false) return false;
        
        
        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        
        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);
        
        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);
        
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        
        return sigok;
    }
    
    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
        // Step 1: the prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) throw;
        
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) throw;
        
        _;
    }
    
    function matchBytes32Prefix(bytes32 content, bytes prefix) internal returns (bool){
        bool match_ = true;
        
        for (var i=0; i<prefix.length; i++){
            if (content[i] != prefix[i]) match_ = false;
        }
        
        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){
        bool checkok;
        
        
        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        checkok = (sha3(keyhash) == sha3(sha256(context_name, queryId)));
        if (checkok == false) return false;
        
        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);
        
        
        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if 'result' is the prefix of sha256(sig1)
        checkok = matchBytes32Prefix(sha256(sig1), result);
        if (checkok == false) return false;
        
        
        // Step 4: commitment match verification, sha3(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);
        
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);
        
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == sha3(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[queryId];
        } else return false;
        
        
        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        checkok = verifySig(sha256(tosign1), sig1, sessionPubkey);
        if (checkok == false) return false;
        
        // verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }
        
        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

    
    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal returns (bytes) {
        uint minLength = length + toOffset;

        if (to.length < minLength) {
            // Buffer too small
            throw; // Should be a better way?
        }

        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }
    
    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    // Duplicate Solidity's ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don't update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can't access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }
  
        return (ret, addr);
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }
        
}
// </ORACLIZE_API>



/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/

contract Oracle is usingOraclize{
    /*Variables*/
    //Private queryId for Oraclize callback
    bytes32 private queryID;
    string public API;
    string public API2;
    string public usedAPI;

    /*Structs*/
    struct QueryInfo {
        uint value;
        bool queried;
        uint date;
        uint calledTime;
        bool called;
    }  
    //Mapping of documents stored in the oracle
    mapping(uint => bytes32) public queryIds;
    mapping(bytes32 => QueryInfo ) public info;

    /*Events*/
    event DocumentStored(uint _key, uint _value);
    event newOraclizeQuery(string description);

    /*Functions*/
    /**
    *@dev Constructor, sets two public api strings
    *e.g. "json(https://api.gdax.com/products/BTC-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
    * or "json(https://api.gdax.com/products/ETH-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
    */
     constructor(string _api, string _api2) public{
        API = _api;
        API2 = _api2;
    }

    /**
    *@dev RetrieveData - Returns stored value by given key
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    */
    function retrieveData(uint _date) public constant returns (uint) {
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.value;
    }

    /**
    *@dev PushData - Sends an Oraclize query for entered API
    */
    function pushData() public payable{
        uint _key = now - (now % 86400);
        uint _calledTime = now;
        QueryInfo storage currentQuery = info[queryIds[_key]];
        require(currentQuery.queried == false  && currentQuery.calledTime == 0 || 
            currentQuery.calledTime != 0 && _calledTime >= (currentQuery.calledTime + 3600) &&
            currentQuery.value == 0);
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize queries sent");
            if (currentQuery.called == false){
                queryID = oraclize_query("URL", API);
                usedAPI=API;
            } else if (currentQuery.called == true ){
                queryID = oraclize_query("URL", API2);
                usedAPI=API2;  
            }

            queryIds[_key] = queryID;
            currentQuery = info[queryIds[_key]];
            currentQuery.queried = true;
            currentQuery.date = _key;
            currentQuery.calledTime = _calledTime;
            currentQuery.called = !currentQuery.called;
        }
    }

    /*
    * gets API used for tests
    */
    function getusedAPI() public view returns(string){
        return usedAPI;
    }
    
    /**
    *@dev Used by Oraclize to return value of PushData API call
    *@param _oraclizeID unique oraclize identifier of call
    *@param _result Result of API call in string format
    */
    function __callback(bytes32 _oraclizeID, string _result) public {
        QueryInfo storage currentQuery = info[_oraclizeID];
        require(msg.sender == oraclize_cbAddress() && _oraclizeID == queryID);
        currentQuery.value = parseInt(_result,3);
        currentQuery.called = false; 
        if(currentQuery.value == 0){
            currentQuery.value = 1;
        }
        emit DocumentStored(currentQuery.date, currentQuery.value);
    }

    /**
    *@dev Allows the contract to be funded in order to pay for oraclize calls
    */
    function fund() public payable {
      
    }

    /**
    *@dev Determine if the Oracle was queried
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    *@return true or false based upon whether an API query has been 
    *initialized (or completed) for given date
    */
    function getQuery(uint _date) public view returns(bool){
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.queried;
    }
}




/**
*The User Contract enables the entering of a deployed swap along with the wrapping of Ether.  This
*contract was specifically made for drct.decentralizedderivatives.org to simplify user metamask 
*calls
*/
contract UserContract{

    using SafeMath for uint256;

    /*Variables*/
    TokenToTokenSwap_Interface internal swap;
    Wrapped_Ether internal baseToken;
    Factory internal factory; 
    address public factory_address;
    address internal owner;

    /*Functions*/
    constructor() public {
        owner = msg.sender;
    }

    /**
    *@dev Value must be sent with Initiate and enter the _amount(in wei) 
    *@param _swapadd is the address of the deployed contract created from the Factory contract
    *@param _amount is the amount of the base tokens(short or long) in the
    *swap. For wrapped Ether, this is wei.
    */
    function Initiate(address _swapadd, uint _amount) payable public{
        require(msg.value == _amount.mul(2));
        swap = TokenToTokenSwap_Interface(_swapadd);
        address token_address = factory.token();
        baseToken = Wrapped_Ether(token_address);
        baseToken.createToken.value(_amount.mul(2))();
        baseToken.transfer(_swapadd,_amount.mul(2));
        swap.createSwap(_amount, msg.sender);
    }

    /**
    *@dev Set factory address 
    *@param _factory_address is the factory address to clone?
    */
    function setFactory(address _factory_address) public {
        require (msg.sender == owner);
        factory_address = _factory_address;
        factory = Factory(factory_address);
    }
}

/**
*This is the basic wrapped Ether contract. 
*All money deposited is transformed into ERC20 tokens at the rate of 1 wei = 1 token
*/
contract Wrapped_Ether {

    using SafeMath for uint256;

    /*Variables*/

    //ERC20 fields
    string public name = "Wrapped Ether";
    uint public total_supply;
    mapping(address => uint) internal balances;
    mapping(address => mapping (address => uint)) internal allowed;

    /*Events*/
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event StateChanged(bool _success, string _message);

    /*Functions*/
    /**
    *@dev This function creates tokens equal in value to the amount sent to the contract
    */
    function createToken() public payable {
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        total_supply = total_supply.add(msg.value);
    }

    /**
    *@dev This function 'unwraps' an _amount of Ether in the sender's balance by transferring 
    *Ether to them
    *@param _value The amount of the token to unwrap
    */
    function withdraw(uint _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        total_supply = total_supply.sub(_value);
        msg.sender.transfer(_value);
    }

    /**
    *@param _owner is the owner address used to look up the balance
    *@return Returns the balance associated with the passed in _owner
    */
    function balanceOf(address _owner) public constant returns (uint bal) { 
        return balances[_owner]; 
    }

    /**
    *@dev Allows for a transfer of tokens to _to
    *@param _to The address to send tokens to
    *@param _amount The amount of tokens to send
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = balances[msg.sender] - _amount;
            balances[_to] = balances[_to] + _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *@dev Allows an address with sufficient spending allowance to send tokens on the behalf of _from
    *@param _from The address to send tokens from
    *@param _to The address to send tokens to
    *@param _amount The amount of tokens to send
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[_from] = balances[_from] - _amount;
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
            balances[_to] = balances[_to] + _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *@dev This function approves a _spender an _amount of tokens to use
    *@param _spender address
    *@param _amount amount the spender is being approved for
    *@return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *@param _owner address
    *@param _spender address
    *@return Returns the remaining allowance of tokens granted to the _spender from the _owner
    */
    function allowance(address _owner, address _spender) public view returns (uint) {
       return allowed[_owner][_spender]; }

    /**
    *@dev Getter for the total_supply of wrapped ether
    *@return total supply
    */
    function totalSupply() public constant returns (uint) {
       return total_supply;
    }
}













