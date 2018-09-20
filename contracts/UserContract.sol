pragma solidity ^0.4.24;


import "./interfaces/TokenToTokenSwap_Interface.sol";
import "./interfaces/ERC20_Interface.sol";
import "./interfaces/OtcInterface.sol";
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
    address public wrapped_address;
    address internal owner;
    OtcInterface oasisDex;
    WETHInterface weth;
    ERC20_Interface dai;


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

    function setWrappedEtherAddress(address _wrapped) public {
        require (msg.sender == owner);
        wrapped_address = _wrapped;
    }



    /**
    *@dev Value must be sent with Initiate and enter the _amount(in wei) 
    *@param _swapadd is the address of the deployed contract created from the Factory contract
    *@param _amount is the amount of the base tokens(short or long) in the
    *swap. For wrapped Ether, this is wei.
    */
    function InitiateWithDai(address _swapadd, uint _amount) payable public{
        require(msg.value == _amount.mul(2));
        swap = TokenToTokenSwap_Interface(_swapadd);
        // Give max allowance to oasisdex to spend weth
        baseToken = Wrapped_Ether(token_address);
        dai = ERC20(_dai);
        weth.deposit.value(msg.value)();
          // Give max allowance to oasisdex to spend weth
        if (weth.allowance(this, oasisDex) < msg.value) {
          weth.approve(oasisDex, uint(-1));
        }
        // Sell the WETH for a minBuyAmt of DAI
        uint daiAmt = oasisDex.sellAllAmount(weth, msg.value, dai, _minBuyAmt);
        dai.transfer(_swapadd,daiAmt);
        swap.createSwap(daiAmt/2, msg.sender);
    }

        /**
    *@dev Value must be sent with Initiate and enter the _amount(in wei) 
    *@param _swapadd is the address of the deployed contract created from the Factory contract
    *@param _amount is the amount of the base tokens(short or long) in the
    *swap. For wrapped Ether, this is wei.
    */
    function CashOutDai() public returns(uint _eth){
        dai = ERC20(_dai);
        if (weth.allowance(this, oasisDex) < _amount) {
          weth.approve(oasisDex, uint(-1));
        }
        // Sell the WETH for a minBuyAmt of DAI
        uint daiAmt = oasisDex.buyAllAmount(weth, msg.value, dai, _minBuyAmt);
        weth.withdraw(daiAmt);
        return daiAmt;

    }
}
