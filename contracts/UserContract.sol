pragma solidity ^0.4.24;


import "./interfaces/TokenToTokenSwap_Interface.sol";
import "./Factory.sol";
import "./Wrapped_Ether.sol";
import "./libraries/SafeMath.sol";

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
    event StartContract(address _newswap, uint _amount);


    /*Functions*/
    constructor() public {
        owner = msg.sender;
    }

    /**
    *@dev Value must be sent with Initiate and enter the _amount(in wei) 
    *@param _startDate is the startDate of the contract you want to deploy
    *@param _amount is the amount of Ether on each side of the contract initially
    */
    function Initiate(uint _startDate, uint _amount) payable public{
        uint _fee = factory.fee();
        require(msg.value == _amount.mul(2) + _fee);
        address _swapadd = factory.deployContract.value(_fee)(_startDate,msg.sender);
        swap = TokenToTokenSwap_Interface(_swapadd);
        address token_address = factory.token();
        baseToken = Wrapped_Ether(token_address);
        baseToken.createToken.value(_amount.mul(2))();
        baseToken.transfer(_swapadd,_amount.mul(2));
        swap.createSwap(_amount, msg.sender);
        emit StartContract(_swapadd,_amount);
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
