pragma solidity ^0.4.24;

/**
*Exchange storage

******how do we make sure the exchagne address is we define 
is the only one allowed to write to this?
*/
contract ExchangeStorage{ 
    /*Variables*/

    
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

    //order_nonce;
    uint internal order_nonce;
    address public owner; //The owner of the market contract
    address[] public openDdaListAssets;
    //Index telling where a specific tokenId is in the forSale array
    address[] public openBooks;
    mapping (address => uint) public openDdaListIndex;
    mapping(address => ListAsset) public listOfAssets;
    //Maps an OrderID to the list of orders
    mapping(uint256 => Order) public orders;
    //An mapping of a token address to the orderID's
    mapping(address =>  uint256[]) public forSale;
    //Index telling where a specific tokenId is in the forSale array
    mapping(uint256 => uint256) internal forSaleIndex;
    
    //mapping of address to position in openBooks
    mapping (address => uint) internal openBookIndex;
    //mapping of user to their orders
    mapping(address => uint[]) public userOrders;
    //mapping from orderId to userOrder position
    mapping(uint => uint) internal userOrderIndex;
    //A list of the blacklisted addresses
    mapping(address => bool) internal blacklist;
    

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
        openBooks.push(address(0));
        order_nonce = 1;
    }


    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    }

    /**
    *@dev allows dev to get the
    */
    function getOwner() external view returns(address){
        return owner;
    }

    /**
    *@dev allows exchange cotract to write the order nonce
    */
    function setOrderNonce(uint _order_nonce) public {
        order_nonce=_order_nonce;
    }
    /**
    *@dev allows dev to get the order nonce
    */
    function getOrderNonce() external view returns(uint){
        return order_nonce;
    }

    /**
    *@dev allows exchange cotract to write the order nonce
    */
    function setOpenDdaListAssets(address _ddaListAsset) public {
        openDdaListAssets.push(_ddaListAsset);
    }
    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getopenDdaListAssets() view public returns (address[]){
        return openDdaListAssets;
    }

    /**
    *@dev allows exchange cotract to write the order nonce
    */
    function setopenDdaListIndex(address _ddaListAsset, uint _value) public {
        openDdaListIndex[_ddaListAsset]= _value ;
    }
    /**
    *@dev getter function to get all openDdaListAssets
    */
    function getopenDdaListIndex(address _ddaListAsset) view public returns (uint){
        return openDdaListIndex[_ddaListAsset];
    }


    /**
    *@dev Gets the DDA List Asset information for the specifed 
    *asset address
    *@param _asset address 
    *@param _amount of asset
    *@param _price uint256 price per unit in wei
    *@param _isLong true if it is long
    *@return price, amount and true if isLong
    */
    function setDdaListAssetInfoAll(address _assetAddress, uint _price, uint _amount, bool _isLong) public {
        ListAsset storage listing = listOfAssets[_assetAddress];
        listing.price = _price;
        listing.amount= _amount;
        listing.isLong= _isLong;
    }

    function setDdaListAssetInfoAmount(address _assetAddress, uint _amount) public {
        ListAsset storage listing = listOfAssets[_assetAddress];
        listing.amount= _amount;
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

    /**
    *@dev Adds to open orderbooks
    *@return _uint of the number of tokens with open orders
    */
    function setOpenBooks(address _openBookAdd) public {
        openBooks.push(_openBookAdd);
    }
    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
    function getBookCount() public constant returns(uint) {
        return openBooks.length;
    }

    //use the nonce for orderId
    function setOrder(uint256 _orderId, address _maker, uint256 _price,uint256 _amount, address _tokenadd) public {
        Order storage _order = orders[_orderId];
        _order.maker = _maker;
        _order.price = _price;
        _order.amount = _amount;
        _order.asset = _tokenadd;
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
        Order storage _order = orders[_orderId];
        return (_order.maker,_order.price,_order.amount,_order.asset);
    }

    function setForSale(address _tokenadd, uint _order_nonce) public {
        forSale[_tokenadd].push(_order_nonce);
    }

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
    function getOrderCount(address _token) public constant returns(uint) {
        return forSale[_token].length;
    }

    function getForSaleOrderId(address _tokenadd) public view returns(uint256[]){
        return forSale[_tokenadd];
    }

    function setForSaleIndex(uint _order_nonce, uint _order_count) public {
        forSaleIndex[_order_nonce]= _order_count;
    }

    function getForSaleIndex(uint _order_nonce) public view returns(uint){
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


    function setOpenBookIndex(address _order, uint _order_index) public {
        openBookIndex[_order]= _order_index;
    }

    function getOpenBookIndex(address _order) public view returns(uint){
        return openBookIndex[_order];
    }

    function setUserOrders(address _user, uint _order_nonce) public {
        userOrders[_user].push(_order_nonce);
    }
    /**
    *@dev getUserOrders allows parties to get an array of all orderId's open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
    function getUserOrders(address _user) public constant returns(uint[]) {
        return userOrders[_user];
    }

    function setUserOrderIndex(address _user, uint _order_nonce) public {
        userOrderIndex[_order_nonce] = userOrders[_user].length;
    }

    function getUserOrderIndex(uint _order_nonce) public view returns(uint){
        return userOrderIndex[_order_nonce];
    }


    /**
    *@notice This allows the owner to stop a malicious party from spamming the orderbook
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    */
    function blacklistParty(address _address, bool _motion) public onlyOwner() {
        blacklist[_address] = _motion;
    }

    /**
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool true for is blacklisted
    */
    function isBlacklist(address _address) public view returns(bool) {
        return blacklist[_address];
    }












}
