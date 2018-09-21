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
    Wrapped_Ether internal weth;
    Factory internal factory; 
    address public factory_address;
    address public wrapped_address;
    address internal owner;
    address public dai_address;
    OtcInterface oasisDex;
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
        weth = Wrapped_Ether(token_address);
        weth.deposit.value(_amount.mul(2))();
        weth.transfer(_swapadd,_amount.mul(2));
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

    function setDaiAddress(address _dai) public {
        require (msg.sender == owner);
        dai_address = _dai;
        dai = ERC20_Interface(_dai);
    }



    /**
    *@dev Value must be sent with Initiate and enter the _amount(in wei) 
    *@param _swapadd is the address of the deployed contract created from the Factory contract
    *@param _amount is the amount of the base tokens(short or long) in the swap. For wrapped Ether, this is wei.
    *@param  _minBuyAmt minimum amount of ETH you want returned
    */
    function InitiateWithDai(address _swapadd, uint _amount,uint _minBuyAmt) payable public{
        require(msg.value == _amount.mul(2));
        swap = TokenToTokenSwap_Interface(_swapadd);
        // Give max allowance to oasisdex to spend weth
        require(dai_address == factory.token());
        weth = Wrapped_Ether(wrapped_address);
        weth.deposit.value(msg.value)();
          // Give max allowance to oasisdex to spend weth
        if (weth.allowance(this, oasisDex) < msg.value) {
          weth.approve(oasisDex, uint(-1));
        }
        // Sell the WETH for a minBuyAmt of DAI
        uint daiAmt = oasisDex.sellAllAmount(wrapped_address, msg.value, dai_address, _minBuyAmt);
        dai.transfer(_swapadd,daiAmt);
        swap.createSwap(daiAmt/2, msg.sender);
    }

        /**
    *@dev Lets you sell your DAI on OasisDex
    *@param  _minBuyAmt minimum amount of ETH you want returned
    */
    function CashOutDai(uint _minBuyAmt) public returns(uint _eth){
        uint _dai = dai.balanceOf(msg.sender);
        if (weth.allowance(this, oasisDex) < _dai) {
          weth.approve(oasisDex, uint(-1));
        }
        // Sell the DAI for a minimum amount of WETH
        uint Amt = oasisDex.sellAllAmount(dai_address,_dai, wrapped_address, _minBuyAmt);
        weth.withdraw(Amt);
        return Amt;
    }
}
