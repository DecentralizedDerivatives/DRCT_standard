pragma solidity ^0.4.24;

 import "./libraries/SafeMath.sol";
 import "./interfaces/ERC20_Interface.sol";

/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange{ 
    using SafeMath for uint256;

    /*Variables*/
    address public owner; //The owner of the market contract
    address internal storage_address;
    Exchange_Interface internal xStorage;

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

    function setdexStorageAddress(address _exchangeStorage) onlyOwner {
        storage_address = _exchangeStorage;
        xStorage = Exchange_Interface(_exchangeStorage);
    }

    /**
    *@dev list allows a party to place an order on the orderbook
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        bool test = xStorage.isBlacklist(msg.sender);
        require(test == false);
        require(_price > 0);
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(token.allowance(msg.sender,address(this)) >= _amount);
        uint fsIndex = xStorage.getOrderCount(_tokenadd);
        if(fsIndex == 0 ){
            xStorage.setForSale(_tokenadd,0);
            }
        xStorage.setForSaleIndex(xStorage.order_nonce,fsIndex);
        xStorage.setForSale(_tokenadd,xStorage.order_nonce);
        xStorage.setOrder(xStorage.order_nonce, msg.sender, _price, _amount,_tokenadd);
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
        if(xStorage.getOpenBookIndex(_tokenadd) == 0){   
            xStorage.setOpenBookIndex(_tokenadd, xStorage.openBooks.length);//would this work? 
            xStorage.setOpenBooks(_tokenadd);
        }
        xStorage.setUserOrderIndex(msg.sender, xStorage.order_nonce);
        xStorage.setUserOrders(msg.sender, xStorage.order_nonce);
        xStorage.order_nonce += 1;
    }

    /**
    *@dev list allows DDA to list an order 
    *@param _asset address 
    *@param _amount of asset
    *@param _price uint256 price per unit in wei
    *@param _isLong true if it is long
    */
    //Then you would have a mapping from an asset to its price/ quantity when you list it.
/*     function listDda(address _asset, uint256 _amount, uint256 _price, bool _isLong) public onlyOwner() {
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        listing.price = _price;
        listing.amount= _amount;
        listing.isLong= _isLong;
        openDdaListIndex[_asset] = openDdaListAssets.length;
        openDdaListAssets.push(_asset);
        
    } */

    /**
    *@dev list allows a DDA to remove asset 
    *@param _asset address 
    */
/*     function unlistDda(address _asset) public onlyOwner() {
        require(blacklist[msg.sender] == false);
        uint256 indexToDelete;
        uint256 lastAcctIndex;
        address lastAdd;
        ListAsset storage listing = listOfAssets[_asset];
        listing.price = 0;
        listing.amount= 0;
        listing.isLong= false;
        indexToDelete = openDdaListIndex[_asset];
        lastAcctIndex = openDdaListAssets.length.sub(1);
        lastAdd = openDdaListAssets[lastAcctIndex];
        openDdaListAssets[indexToDelete]=lastAdd;
        openDdaListIndex[lastAdd]= indexToDelete;
        openDdaListAssets.length--;
        openDdaListIndex[_asset] = 0;
    } */

    /**
    *@dev buy allows a party to partially fill an order
    *@param _asset is the address of the assset listed
    *@param _amount is the amount of tokens to buy
    */
/*     function buyPerUnit(address _asset, uint256 _amount) external payable {
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        require(_amount <= listing.amount);
        uint totalPrice = _amount.mul(listing.price);
        require(msg.value == totalPrice);
        ERC20_Interface token = ERC20_Interface(_asset);
        if(token.allowance(owner,address(this)) >= _amount){
            assert(token.transferFrom(owner,msg.sender, _amount));
            owner.transfer(totalPrice);
            listing.amount= listing.amount.sub(_amount);
        }
    } */

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
/*     function unlist(uint256 _orderId) external{
        require(forSaleIndex[_orderId] > 0);
        Order memory _order = orders[_orderId];
        require(msg.sender== _order.maker || msg.sender == owner);
        unLister(_orderId,_order);
        emit OrderRemoved(msg.sender,_order.asset,_order.amount,_order.price);
    } */

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
/*     function buy(uint256 _orderId) external payable {
        Order memory _order = orders[_orderId];
        require(_order.price != 0 && _order.maker != address(0) && _order.asset != address(0) && _order.amount != 0);
        require(msg.value == _order.price);
        require(blacklist[msg.sender] == false);
        address maker = _order.maker;
        ERC20_Interface token = ERC20_Interface(_order.asset);
        if(token.allowance(_order.maker,address(this)) >= _order.amount){
            assert(token.transferFrom(_order.maker,msg.sender, _order.amount));
            maker.transfer(_order.price);
        }
        unLister(_orderId,_order);
        emit Sale(msg.sender,_order.asset,_order.amount,_order.price);
    } */

    /**
    *@dev getOrder lists the price,amount, and maker of a specific token for a sale
    *@param _orderId uint256 ID of order
    *@return address of the party selling
    *@return uint of the price of the sale (in wei)
    *@return uint of the order amount of the sale
    *@return address of the token
    */
/*     function getOrder(uint256 _orderId) external view returns(address,uint,uint,address){
        Order storage _order = orders[_orderId];
        return (_order.maker,_order.price,_order.amount,_order.asset);
    } */

    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
/*     function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    } */

    /**
    *@notice This allows the owner to stop a malicious party from spamming the orderbook
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    */
/*     function blacklistParty(address _address, bool _motion) public onlyOwner() {
        blacklist[_address] = _motion;
    } */

    /**
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool true for is blacklisted
    */
/*     function isBlacklist(address _address) public view returns(bool) {
        return blacklist[_address];
    } */

    /**
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@param _token address used to count the number of orders
    *@return _uint of the number of orders in the orderbook
    */
/*     function getOrderCount(address _token) public constant returns(uint) {
        return forSale[_token].length;
    } */

    /**
    *@dev Gets number of open orderbooks
    *@return _uint of the number of tokens with open orders
    */
/*     function getBookCount() public constant returns(uint) {
        return openBooks.length;
    } */

    /**
    *@dev getOrders allows parties to get an array of all orderId's open for a given token
    *@param _token address of the drct token
    *@return _uint[] an array of the orders in the orderbook
    */
/*     function getOrders(address _token) public constant returns(uint[]) {
        return forSale[_token];
    } */

    /**
    *@dev getUserOrders allows parties to get an array of all orderId's open for a given user
    *@param _user address 
    *@return _uint[] an array of the orders in the orderbook for the user
    */
/*     function getUserOrders(address _user) public constant returns(uint[]) {
        return userOrders[_user];
    } */

    /**
    *@dev getter function to get all openDdaListAssets
    */
/*     function getopenDdaListAssets() view public returns (address[]){
        return openDdaListAssets;
    } */
    /**
    *@dev Gets the DDA List Asset information for the specifed 
    *asset address
    *@param _assetAddress for DDA list
    *@return price, amount and true if isLong
    */
/*     function getDdaListAssetInfo(address _assetAddress) public view returns(uint, uint, bool){
        return(listOfAssets[_assetAddress].price,listOfAssets[_assetAddress].amount,listOfAssets[_assetAddress].isLong);
    } */
    /**
    *@dev An internal function to update mappings when an order is removed from the book
    *@param _orderId is the uint256 ID of order
    *@param _order is the struct containing the details of the order
    */
/*     function unLister(uint256 _orderId, Order _order) internal{
            uint256 tokenIndex;
            uint256 lastTokenIndex;
            address lastAdd;
            uint256  lastToken;
        if(forSale[_order.asset].length == 2){
            tokenIndex = openBookIndex[_order.asset];
            lastTokenIndex = openBooks.length.sub(1);
            lastAdd = openBooks[lastTokenIndex];
            openBooks[tokenIndex] = lastAdd;
            openBookIndex[lastAdd] = tokenIndex;
            openBooks.length--;
            openBookIndex[_order.asset] = 0;
            forSale[_order.asset].length -= 2;
        }
        else{
            tokenIndex = forSaleIndex[_orderId];
            lastTokenIndex = forSale[_order.asset].length.sub(1);
            lastToken = forSale[_order.asset][lastTokenIndex];
            forSale[_order.asset][tokenIndex] = lastToken;
            forSaleIndex[lastToken] = tokenIndex;
            forSale[_order.asset].length--;
        }
        forSaleIndex[_orderId] = 0;
        orders[_orderId] = Order({
            maker: address(0),
            price: 0,
            amount:0,
            asset: address(0)
        });
        if(userOrders[_order.maker].length > 1){
            tokenIndex = userOrderIndex[_orderId];
            lastTokenIndex = userOrders[_order.maker].length.sub(1);
            lastToken = userOrders[_order.maker][lastTokenIndex];
            userOrders[_order.maker][tokenIndex] = lastToken;
            userOrderIndex[lastToken] = tokenIndex;
        }
        userOrders[_order.maker].length--;
        userOrderIndex[_orderId] = 0;
    } */
}
