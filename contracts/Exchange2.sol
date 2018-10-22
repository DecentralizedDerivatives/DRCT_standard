pragma solidity ^0.4.24;

 import "./libraries/SafeMath.sol";
 import "./ExchangeStorage.sol";


/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange2{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    address internal storage_address;
    ExchangeStorage internal xStorage;

    /*Structs*/
    //This is the base data structure for an order (the maker of the order and the price)
    struct Order {
        address maker;// the placer of the order
        address asset;
        uint price;// The price in wei
        uint amount;
    }

    struct ListAsset {
        uint price;
        uint amount;
        bool isLong;  
    }
   
    //mapping(address => bool) public blacklist;

    /*Events*/
    event OrderPlaced(address _sender,address _token, uint256 _amount, uint256 _price);
    event Sale(address _sender,address _token, uint256 _amount, uint256 _price);
    event OrderRemoved(address _sender,address _token, uint256 _amount, uint256 _price);
    event test(uint allow, uint allowleft );
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
        //openBooks.push(address(0));
        //order_nonce = 1;
    }

    function setDexStorageAddress(address _exchangeStorage) public onlyOwner {
        storage_address = _exchangeStorage;
        xStorage = ExchangeStorage(_exchangeStorage);
    }

    function getDexStorageAddress() public constant returns(address) {
        return storage_address;
    }


    /**
    *@dev list allows a party to place an order on the orderbookas
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require (xStorage.isBlacklist(msg.sender)==false  && _price > 0); 
        uint allow = xStorage.listCheckAllowance(_tokenadd,msg.sender, _amount);
        uint allowleft = xStorage.setAllowedLeftToList(_tokenadd,msg.sender, _amount);
        emit test(allow, allowleft);
        require(xStorage.getAllowedLeftToList(msg.sender,storage_address)>= _amount);
        uint fsIndex = xStorage.getOrderCount(_tokenadd);
        if(fsIndex == 0 ){
            xStorage.setForSale(_tokenadd,0);
            }
        uint _order_nonce = xStorage.getOrderNonce();  
        xStorage.setForSaleIndex(_order_nonce,fsIndex);
        xStorage.setForSale(_tokenadd,_order_nonce);
        xStorage.setOrder(_order_nonce, msg.sender, _price, _amount,_tokenadd);
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
        if(xStorage.getOpenBookIndex(_tokenadd) == 0){   
            xStorage.setOpenBookIndex(_tokenadd, xStorage.getBookCount());
            xStorage.setOpenBooks(_tokenadd);
        }
        xStorage.setUserOrderIndex(msg.sender, _order_nonce);
        xStorage.setUserOrders(msg.sender, _order_nonce);
        _order_nonce += 1;
        xStorage.setOrderNonce(_order_nonce);   
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
        xStorage.buyPerUnitTransfer(_asset, _amount, msg.sender, totalPrice); 
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
        xStorage.buyTransfer(_orderId, msg.sender);
        xStorage.unLister(_orderId);
        emit Sale(msg.sender,_order_asset,_order_amount,_order_price);
    }  

    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    } 

    /**
    *@dev allows dev to get the owner from the contract
    */
    function getOwner() public view returns(address){
        return owner;
    }
}

