pragma solidity ^0.4.23;

import "../interfaces/Oracle_Interface.sol";
import "../interfaces/DRCT_Token_Interface.sol";
import "../interfaces/Factory_Interface.sol";
import "../interfaces/ERC20_Interface.sol";
import "./SafeMath.sol";


/**
*This contract is the specific DRCT base contract that holds the funds of the contract and
*redistributes them based upon the change in the underlying values
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
    *@param _factory_address
    *@param _creator address of swap creator
    *@param _userContract 
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
    @dev A getter function for retriving standardized variables from the factory contract
    */
    function showPrivateVars(SwapStorage storage self) internal view returns (address[5],uint, uint, uint, uint, uint){
        return ([self.userContract, self.long_token_address,self.short_token_address, self.oracle_address, self.token_address], self.num_DRCT_tokens, self.contract_details[2], self.contract_details[3], self.contract_details[0], self.contract_details[1]);
    }
    // [userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens,  duration,start_value, Start date, end_date, multiplier

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
    */
    function getVariables(SwapStorage storage self) internal{
        (self.oracle_address,self.contract_details[3],self.contract_details[2],self.token_address,self.contract_details[6]) = self.factory.getVariables();
    }

    /**
    *@dev check if the oracle has been queried within the last day 
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
    *What should we do about zeroed out values? 
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
