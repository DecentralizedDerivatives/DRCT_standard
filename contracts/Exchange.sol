pragma solidity ^0.4.24;

 import "./libraries/SafeMath.sol";
 import "./ExchangeStorage.sol";
import "./interfaces/ERC20_Interface.sol";

/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    ExchangeStorage internal xStorage;

    /*Events*/
    event OrderPlaced(address _sender,address _token, uint256 _amount, uint256 _price);
    event Sale(address _sender,address _token, uint256 _amount, uint256 _price);
    event OrderRemoved(address _sender,address _token, uint256 _amount, uint256 _price);
    event test(uint allow );
    event test2(uint allowleft );
    /*Modifiers*/
    /**
    *@dev Access modifier for Owner functionality
    */
    modifier onlyOwner() {
        require(msg.sender == xStorage.getOwner());
        _;
    }

    /*Functions*/
    /**
    *@dev the constructor argument to set the owner and initialize the array.
    */
    constructor() public{
        xStorage.setOwner(msg.sender);
        xStorage.setOpenBooks(address(0));
        xStorage.setOrderNonce(1);
    }




    function setOwner(address _owner) public onlyOwner{
       xStorage.setOwner(_owner);
    }




    /**
    *@dev list allows a party to place an order on the orderbookas
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require (xStorage.isBlacklist(msg.sender)==false  && _price > 0); 
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(xStorage.getTotalListed(msg.sender,_tokenadd) +_amount >= token.allowance(msg.sender,address(this)));
        uint fsIndex = xStorage.getOrderCount(_tokenadd);
        if(fsIndex == 0 ){
            xStorage.setForSale(_tokenadd,0);
            }
        uint _order_nonce = xStorage.getOrderNonce();  
        xStorage.setForSaleIndex(_order_nonce,fsIndex);
        xStorage.setForSale(_tokenadd,_order_nonce);
        xStorage.setOrder(_order_nonce, msg.sender, _price, _amount,_tokenadd);
        if(xStorage.getOpenBookIndex(_tokenadd) == 0){   
            xStorage.setOpenBookIndex(_tokenadd, xStorage.getBookCount());
            xStorage.setOpenBooks(_tokenadd);
        }
        xStorage.setUserOrderIndex(msg.sender, _order_nonce);
        xStorage.setUserOrders(msg.sender, _order_nonce);
        xStorage.setOrderNonce(_order_nonce + 1);
        xStorage.setTotalListed(_tokenadd,msg.sender,_amount);
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
    }

    /**
    *@dev list allows DDA to list an order 
    *@param _asset address 
    *@param _amount of asset
    *@param _price uint256 price per unit in wei
    *@param _isLong true if it is long
    */
    //Then you would have a mapping from an asset to its price/ quantity when you list it.
    function listDda(address _asset, uint256 _amount, uint256 _price, bool _isLong) public onlyOwner() {
        require (xStorage.isBlacklist(msg.sender)==false);
        xStorage.setDdaListAssetInfoAll( _asset, _price,  _amount, _isLong);
        xStorage.setOpenDdaListIndex(_asset, xStorage.getCountopenDdaListAssets());
        xStorage.setOpenDdaListAssets(_asset);      
    }  

    /**
    *@notice This allows the owner to stop a malicious party from spamming the orderbook
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    */
    function blacklistParty(address _address, bool _motion) public onlyOwner {
        xStorage.blacklistParty(_address,_motion);
    }
    /**
    *@dev list allows a DDA to remove asset 
    *@param _asset address 
    */
    function unlistDda(address _asset) public onlyOwner() {
        require (xStorage.isBlacklist(msg.sender)==false);
        uint256 indexToDelete;
        uint256 lastAcctIndex;
        address lastAdd;
        xStorage.setDdaListAssetInfoAll(_asset, 0, 0, false); 
        indexToDelete = xStorage.getOpenDdaListIndex(_asset);
        lastAcctIndex = xStorage.getCountopenDdaListAssets().sub(1);
        lastAdd = xStorage.getOpenDdaListAddbyIndex(lastAcctIndex);
        xStorage.setOpenDdaListAssetByIndex(indexToDelete, lastAdd);
        xStorage.setOpenDdaListIndex(lastAdd, indexToDelete);
        xStorage.setOpenDdaArrayLength(); 
        xStorage.setOpenDdaListIndex(_asset, 0);
    } 

    /**
    *@dev buy allows a party to partially fill an order
    *@param _asset is the address of the assset listed
    *@param _amount is the amount of tokens to buy
    */
    function buyPerUnit(address _asset, uint256 _amount) external payable {
        require (xStorage.isBlacklist(msg.sender)==false);
        uint listing_amount = xStorage.getDdaListAssetInfoAmount(_asset);
        require(_amount <= listing_amount);
        uint totalPrice = _amount.mul(listing_amount);
        require(msg.value == totalPrice);
        ERC20_Interface token = ERC20_Interface(_asset);
        if(token.allowance(owner,address(this)) >= _amount){
            assert(token.transferFrom(owner,msg.sender, _amount));
            owner.transfer(totalPrice);
            xStorage.setDdaListAssetInfoAmount(_asset,listing_amount.sub(_amount));
        }
    } 

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
     function unlist(uint256 _orderId) external{
        require(xStorage.getForSaleIndex(_orderId) > 0);
        require(msg.sender == xStorage.getOrderMaker(_orderId)  || msg.sender == owner);
        xStorage.unLister(_orderId);
        address _order_asset = xStorage.getOrderAsset(_orderId);
        uint _order_price = xStorage.getOrderPrice(_orderId);
        uint _order_amount = xStorage.getOrderAmount(_orderId);
        emit OrderRemoved(msg.sender, _order_asset,_order_amount,_order_price);
    } 

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
        address _order_maker = xStorage.getOrderMaker(_orderId);
        address _order_asset = xStorage.getOrderAsset(_orderId);
        uint _order_price = xStorage.getOrderPrice(_orderId);
        uint _order_amount = xStorage.getOrderAmount(_orderId);
        require(_order_price != 0 && _order_maker != address(0) && _order_asset != address(0) && _order_amount!= 0);
        require(msg.value == _order_price);
        require(xStorage.isBlacklist(msg.sender) == false);
        ERC20_Interface token = ERC20_Interface(_order_asset);
        assert(token.transferFrom(_order_maker,msg.sender, _order_amount));
        _order_maker.transfer(_order_price);
        xStorage.unLister(_orderId);
        emit Sale(msg.sender,_order_asset,_order_amount,_order_price);
    }  
}

