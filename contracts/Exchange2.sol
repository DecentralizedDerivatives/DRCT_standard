pragma solidity ^0.4.24;

 import "./libraries/SafeMath.sol";
 import "./interfaces/ERC20_Interface.sol";
 import "./interfaces/Exchange_Interface.sol";

/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange2{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    address internal storage_address;
    Exchange_Interface internal xStorage;

    /*Structs*/
    //This is the base data structure for an order (the maker of the order and the price)
    struct Order {
        address maker;// the placer of the order
        uint price;// The price in wei
        uint amount;
        address asset;
    }

    struct ListAsset {
        uint price;
        uint amount;
        bool isLong;  
    }
/*     using ExchangeStorage for ExchangeStorage.Order;
    ExchangeStorage.Order public Order; */

    /* using ExchangeStorage for ExchangeStorage.ListAsset;
    ExchangeStorage.ListAsset public ListAsset; */


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
        xStorage = Exchange_Interface(_exchangeStorage);
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
        lastAdd = getOpenDdaListAssets[lastAcctIndex];
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
        require(forSaleIndex[_orderId] > 0);
        Order memory _order = orders[_orderId];///how to set _order?????
        require(msg.sender== getOrderMaker(_orderId) || msg.sender == owner);
        xStorage.unLister(_orderId,_order);////how to set _order
        emit OrderRemoved(msg.sender,_order.asset,_order.amount,_order.price);
    } 

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
        getOrder(_orderId);
        Order memory _order = orders[_orderId];///how to set _order?????
        require(_order.price != 0 && _order.maker != address(0) && _order.asset != address(0) && _order.amount != 0);
        require(msg.value == _order.price);
        require(isBlacklist(msg.sender) == false);
        address maker = getOrderMaker(_orderId);
        ERC20_Interface token = ERC20_Interface(_order.asset);
        if(token.allowance(_order.maker,address(this)) >= _order.amount){
            assert(token.transferFrom(_order.maker,msg.sender, _order.amount));
            maker.transfer(_order.price);
        }
        xStorage.unLister(_orderId,_order);
        emit Sale(msg.sender,_order.asset,_order.amount,_order.price);
    }  

    /**
    *@dev getOrder lists the price,amount, and maker of a specific token for a sale
    *@param _orderId uint256 ID of order
    *@return address of the party selling
    *@return uint of the price of the sale (in wei)
    *@return uint of the order amount of the sale
    *@return address of the token
    */
    function getOrder(uint256 _orderId) external view returns(address,uint,uint,address){
        Order storage _order = orders[_orderId];///how to set _order?????
        return (_order.maker,_order.price,_order.amount,_order.asset);
    } 

    function getOrderMaker(uint256 _orderId) external view returns(address)  {
        Order storage _order = orders[_orderId];
        return (_order.maker);
    }

    function getOrderPrice(uint256 _orderId) external view returns(uint)  {
        Order storage _order = orders[_orderId];
        return (_order.price);
    } 

    function getOrderAmount(uint256 _orderId) external view returns(uint){
        Order storage _order = orders[_orderId];
        return (_order.amount);
    }

    function getOrderAsset(uint256 _orderId) external view returns(address){
        Order storage _order = orders[_orderId];
        return (_order.asset);
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
        return xStorage.blacklist[_address];
    } 

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
     function getOrderCount(address _token) public constant returns(uint) {
        return forSale[_token].length;
    } 

    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
     function getBookCount() public constant returns(uint) {
        return openBooks.length;
    }

    /**
    *@dev getOrders allows parties to get an array of all orderId's open for a given token
    *@param _token address of the drct token
    *@return _uint[] an array of the orders in the orderbook
    */
    function getOrders(address _token) public constant returns(uint[]) {
        return forSale[_token];
    } 

    /**
    *@dev getUserOrders allows parties to get an array of all orderId's open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
    function getUserOrders(address _user) public constant returns(uint[]) {
        return userOrders[_user];
    } 

    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getopenDdaListAssets() view public returns (address[]){
        return openDdaListAssets;
    } 
    /**
    *@dev Gets the DDA List Asset information for the specifed 
    *asset address
    *@param _assetAddress for DDA list
    *@return price, amount and true if isLong
    */
    function getDdaListAssetInfo(address _assetAddress) public view returns(uint, uint, bool){
        return(listOfAssets[_assetAddress].price,listOfAssets[_assetAddress].amount,listOfAssets[_assetAddress].isLong);
    } 

    function getDdaListAssetInfoAmount(address _assetAddress) public returns(uint) {
        ListAsset storage listing = listOfAssets[_assetAddress];
        return listing.amount= _amount;
    }

    function getDdaListAssetInfoPrice(address _assetAddress) public returns(uint) {
        ListAsset storage listing = listOfAssets[_assetAddress];
        return listing.price;
    }

    /**
    *@dev This function returns the _amount of tokens a _spender(exchange) can list
    *@param _spender address
    *@param _amount amount the spender is being approved for
    *@return true if spender appproved successfully
    */
    function getAllowedLeftToList(address _owner, address _spender, uint _amount) public returns (uint) {
        return xStorage.allowedLeft[_owner][_spender];
        
    }

    /**
    *@dev allows dev to get the owner from the storage contract
    */
    function getOwner() external view returns(address){
        return xStorage.owner;
    }

    /**
    *@dev allows dev to get the order nonce
    */
    function getOrderNonce() external view returns(uint) {
        return xStorage.order_nonce;
    }

    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getopenDdaListAssets() view public returns (address[]) {
        return xStorage.openDdaListAssets;
    }
    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getCountopenDdaListAssets() view public returns (uint) {
        return xStorage.openDdaListAssets.length;
    }

    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getOpenDdaListIndex(address _ddaListAsset) view public returns (uint)  {
        return xStorage.openDdaListIndex[_ddaListAsset];
    }

    /**
    *@dev Gets the DDA List Asset information for the specifed 
    *asset address
    *@param _assetAddress for DDA list
    *@return price, amount and true if isLong
    */
    function getDdaListAssetInfo(address _assetAddress) public view returns(uint, uint, bool) {
        return(xStorage.listOfAssets[_assetAddress].price,xStorage.listOfAssets[_assetAddress].amount,xStorage.listOfAssets[_assetAddress].isLong);
    }





    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
    function getBookCount() public constant returns(uint) {
        return openBooks.length;
    }

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
    function getOrderCount(address _token) public constant returns(uint)  {
        return forSale[_token].length;
    }

    function getForSaleOrderId(address _tokenadd) public view returns(uint256[])  {
        return forSale[_tokenadd];
    }
    function getForSaleIndex(uint _order_nonce) public view returns(uint)  {
        return forSaleIndex[_order_nonce];
    }

    /**
    *@dev getOrders allows parties to get an array of all orderId's open for a given token
    *@param _token address of the drct token
    *@return _uint[] an array of the orders in the orderbook
    */
    function getOrders(address _token) public constant returns(uint[]) {
        return forSale[_token];
    }

    function getOpenBookIndex(address _order) public view returns(uint) {
        return openBookIndex[_order];
    }

    /**
    *@dev getUserOrders allows parties to get an array of all orderId's open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
    function getUserOrders(address _user) public constant returns(uint[]) {
        return userOrders[_user];
    }

    function getUserOrderIndex(uint _order_nonce) public view returns(uint) {
        return userOrderIndex[_order_nonce];
    }

    /**
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool true for is blacklisted
    */
    function isBlacklist(address _address) external view returns(bool) {
        return blacklist[_address];
    }

}
