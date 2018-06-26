pragma solidity ^0.4.23;

import "./libraries/TokenLibrary.sol";

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