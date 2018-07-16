pragma solidity ^0.4.21;

import "./libraries/DRCTLibrary.sol";

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
    constructor(address _factory) public {
        drct.startToken(_factory);
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
        drct.getFactoryAddress();
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