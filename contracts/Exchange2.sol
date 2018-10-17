pragma solidity ^0.4.24;

 import "./libraries/SafeMath.sol";
 import "./interfaces/ERC20_Interface.sol";


/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange2{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    address internal storage_address;
    ExchangeStorage internal xStorage;
    //Order orders;
    //ListAsset listAssets;

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
        require (isBlacklist(msg.sender)==false  && _price > 0); 
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        //require(token.allowance(msg.sender,address(this)) >= _amount);
        require(token.allowance(msg.sender,storage_address) >= _amount);
        uint totalAllowance = getAllowedLeftToList(msg.sender,address(this)).sub(_amount);
        xStorage.setAllowedLeftToList(address(this), totalAllowance);
        uint fsIndex = getOrderCount(_tokenadd);
        if(fsIndex == 0 ){
            xStorage.setForSale(_tokenadd,0);
            }
        uint _order_nonce = getOrderNonce();  
        xStorage.setForSaleIndex(_order_nonce,fsIndex);
        xStorage.setForSale(_tokenadd,_order_nonce);
        xStorage.setOrder(_order_nonce, msg.sender, _price, _amount,_tokenadd);
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
        if(getOpenBookIndex(_tokenadd) == 0){   
            xStorage.setOpenBookIndex(_tokenadd, getBookCount());
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
        require (isBlacklist(msg.sender)==false);
        xStorage.setDdaListAssetInfoAll( _asset, _price,  _amount, _isLong);
        xStorage.setOpenDdaListIndex(_asset, getCountopenDdaListAssets());
        xStorage.setOpenDdaListAssets(_asset);      
    }  

    /**
    *@dev list allows a DDA to remove asset 
    *@param _asset address 
    */
    function unlistDda(address _asset) public onlyOwner() {
        require (isBlacklist(msg.sender)==false);
        uint256 indexToDelete;
        uint256 lastAcctIndex;
        address lastAdd;
        xStorage.setDdaListAssetInfoAll(_asset, 0, 0, false); 
        indexToDelete = getOpenDdaListIndex(_asset);
        lastAcctIndex = getCountopenDdaListAssets().sub(1);
        lastAdd = getOpenDdaListAddbyIndex(lastAcctIndex);
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
        require (isBlacklist(msg.sender)==false);
        uint listing_amount = getDdaListAssetInfoAmount(_asset);
        require(_amount <= listing_amount);
        uint totalPrice = _amount.mul(listing_amount);
        require(msg.value == totalPrice);
        ERC20_Interface token = ERC20_Interface(_asset);
        if(token.allowance(owner,address(this)) >= _amount){
            assert(token.transferFrom(owner,msg.sender, _amount));
            owner.transfer(totalPrice);
            listing_amount= listing_amount.sub(_amount);
            xStorage.setDdaListAssetInfoAmount(_asset,listing_amount);
            
        }
    } 

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
     function unlist(uint256 _orderId) external{
        require(getForSaleIndex(_orderId) > 0);
        require(msg.sender == getOrderMaker(_orderId)  || msg.sender == owner);
        xStorage.unLister(_orderId);////how to set _order
        address _order_asset = getOrderAsset(_orderId);
        uint _order_price = getOrderPrice(_orderId);
        uint _order_amount = getOrderAmount(_orderId);
        emit OrderRemoved(msg.sender, _order_asset,_order_amount,_order_price);
    } 

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
        address _order_maker = getOrderMaker(_orderId);
        address _order_asset = getOrderAsset(_orderId);
        uint _order_price = getOrderPrice(_orderId);
        uint _order_amount = getOrderAmount(_orderId);
        require(_order_price != 0 && _order_maker != address(0) && _order_asset != address(0) && _order_amount!= 0);
        require(msg.value == _order_price);
        require(isBlacklist(msg.sender) == false);
        
        ERC20_Interface token = ERC20_Interface(_order_asset);
        if(token.allowance(_order_maker,address(this)) >= _order_amount){
            assert(token.transferFrom(_order_maker,msg.sender, _order_amount));
            _order_maker.transfer(_order_price);
        }
        xStorage.unLister(_orderId);
        emit Sale(msg.sender,_order_asset,_order_amount,_order_price);
    }  

    /**
    *@dev getOrder lists the price,amount, and maker of a specific token for a sale
    *@param _orderId uint256 ID of order
    *@return address of the party selling
    *@return uint of the price of the sale (in wei)
    *@return uint of the order amount of the sale
    *@return address of the token
    */
    function getOrder(uint256 _orderId) public view returns(address _maker,address _asset,uint _price,uint _amount){
        (_maker, _asset,_price,_amount) = xStorage.orders(_orderId);
    } 
    
    function getOrderNoMaker(uint256 _orderId) public view returns(address _asset,uint _price,uint _amount){
        address _maker;
        (_maker,_asset,_price,_amount) = xStorage.orders(_orderId);
    } 

    function getOrderMaker(uint256 _orderId) public view returns(address _maker)  {
        address _asset;
        uint _price;
        uint _amount;
        (_maker, _asset,_price,_amount)  = xStorage.orders(_orderId);
    }

    function getOrderPrice(uint256 _orderId) public view returns(uint _price)  {
        address _maker;
        address _asset;
        uint _amount;
        (_maker, _asset,_price,_amount)  = xStorage.orders(_orderId);
    } 

    function getOrderAmount(uint256 _orderId) public view returns(uint _amount){
        address _maker;
        address _asset;
        uint _price;
        (_maker, _asset,_price,_amount)  = xStorage.orders(_orderId);
    }

    function getOrderAsset(uint256 _orderId) public view returns(address _asset){
        address _maker;
        uint _price;
        uint _amount;
        (_maker, _asset,_price,_amount)  = xStorage.orders(_orderId);
    }

    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    } 

    /**
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool true for is blacklisted
    */
     function isBlacklist(address _address) public view returns(bool) {
        return xStorage.isBlacklist(_address);
    } 

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
     function getOrderCount(address _token) public constant returns(uint) {
        return xStorage.forSale[_token].length;
    } 

    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
     function getBookCount() public constant returns(uint) {
        return xStorage.openBooks.length;
    }

    /**
    *@dev getOrders allows parties to get an array of all orderId's open for a given token
    *@param _token address of the drct token
    *@return _uint[] an array of the orders in the orderbook
    */
    function getOrders(address _token) public constant returns(uint[]) {
        return xStorage.forSale[_token];
    } 

    /**
    *@dev getUserOrders allows parties to get an array of all orderId's open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
    function getUserOrders(address _user) public constant returns(uint[]) {
        return xStorage.userOrders[_user];
    } 

    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getopenDdaListAssets() view public returns (address[]){
        return xStorage.openDdaListAssets;
    } 

    /**
    *@dev getter function to get addres of openDdaListAsset for specified index
    */
    function getOpenDdaListAddbyIndex(uint _index) view public returns (address)  {
        return xStorage.openDdaListAssets[_index];
    }
    /**
    *@dev Gets the DDA List Asset information for the specifed 
    *asset address
    *@param _assetAddress for DDA list
    *@return price, amount and true if isLong
    */
    function getDdaListAssetInfo(address _assetAddress) public view returns(uint _price, uint _amount, bool _isLong){
        (_price, _amount, _isLong) = xStorage.listOfAssets[_assetAddress];
    } 

    function getDdaListAssetInfoAmount(address _assetAddress) public returns(uint _amount) {
        uint _price;
        bool _isLong;
        (_price, _amount, _isLong) = xStorage.listOfAssets[_assetAddress];
        
    }

    function getDdaListAssetInfoPrice(address _assetAddress) public returns(uint _price) {
        uint _amount;
        bool _isLong;
        (_price, _amount, _isLong) = xStorage.listOfAssets[_assetAddress];
    }

    /**
    *@dev This function returns the _amount of tokens a _spender(exchange) can list
    *@param _spender address
    *@param _amount amount the spender is being approved for
    *@return true if spender appproved successfully
    */
    function getAllowedLeftToList(address _owner, address _spender) public returns (uint) {
        return xStorage.allowedLeft[_owner][_spender];
        
    }

    /**
    *@dev allows dev to get the owner from the storage contract
    */
    function getOwner() public view returns(address){
        return xStorage.owner;
    }

    /**
    *@dev allows dev to get the order nonce
    */
    function getOrderNonce() public view returns(uint) {
        return xStorage.order_nonce;
    }

    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getOpenDdaListAssets() view public returns (address[]) {
        return xStorage.openDdaListAssets;
    }
    /**
    *@dev getter function to get openDdaListAssets length/count
    */
    function getCountopenDdaListAssets() view public returns (uint) {
        return xStorage.openDdaListAssets.length;
    }

    /**
    *@dev getter function to get index by address for openDdaListAssets
    */
    function getOpenDdaListIndex(address _ddaListAsset) view public returns (uint)  {
        return xStorage.openDdaListIndex[_ddaListAsset];
    }

    function getForSaleOrderId(address _tokenadd) public view returns(uint256[])  {
        return xStorage.forSale[_tokenadd];
    }
    function getForSaleIndex(uint _order_nonce) public view returns(uint)  {
        return xStorage.forSaleIndex[_order_nonce];
    }

    function getOpenBookIndex(address _order) public view returns(uint) {
        return xStorage.openBookIndex[_order];
    }


    function getUserOrderIndex(uint _order_nonce) public view returns(uint) {
        return xStorage.userOrderIndex[_order_nonce];
    }


}

