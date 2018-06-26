pragma solidity ^0.4.23;

import "./TokenToTokenSwap.sol";
import "./CloneFactory.sol";

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
