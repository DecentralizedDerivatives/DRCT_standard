pragma solidity ^0.4.17;

import "./DRCT_Token.sol";

/**Swap Token Deployer Contract-- purpose is to save gas for deployment of Factory contract
 *It also ensures only the factory can create new tokens
*/
contract TokenDeployer {
    /*Variables*/
    address internal owner;
    address public factory;

    /*Functions*/
    /**
     *@dev Deploys the factory contract 
     *@param _factory is the address of the factory contract
    */  
    function TokenDeployer(address _factory) public {
        factory = _factory;
        owner = msg.sender;
    }

    /**
     *@notice The function creates a new tokens
     *@dev It ensures the new tokens can only be created by the factory
     *@return returns the address for the new token
    */
    function newToken() public returns (address created) {
        require(msg.sender == factory);
        address new_token = new DRCT_Token(factory);
        return new_token;
    }

    /**
     *@dev Allows owner to set variables in contract
     *@param _factory
     *@param _owner
    */
    function setVars(address _factory, address _owner) public {
        require (msg.sender == owner);
        factory = _factory;
        owner = _owner;
    }
}
