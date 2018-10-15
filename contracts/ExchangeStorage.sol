pragma solidity ^0.4.24;

/**
*Exchange storage

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
    uint public order_nonce;
    mapping(address => mapping (address => uint)) internal allowedLeft;
    address public owner; //The owner of the market contract
    address public dexAddress;
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

    modifier onlyDex() {
        require(msg.sender == dexAddress);
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

    function setDexAddress(address _dexAddress) public onlyOwner {
        dexAddress = _dexAddress;
    }
    function getDexAddress() external view returns(address) {
        return dexAddress ;
    }

    /**
    *@dev This function updates the _amount of tokens a _spender(exchange) can list
    *@param _spender address
    *@param _amount amount the spender is being approved for
    *@return true if spender appproved successfully
    */
    function setAllowedLeftToList(address _spender, uint _amount) public {
        allowedLeft[msg.sender][_spender] = _amount;

    }
    /**
    *@dev allows exchange contract to write the order nonce
    */
    function setOrderNonce(uint _order_nonce) public onlyDex {
        order_nonce=_order_nonce;
    }

    /**
    *@dev allows exchange contract to add address to OpenDdaListAssets
    */
    function setOpenDdaListAssets(address _ddaListAsset) public onlyDex {
        openDdaListAssets.push(_ddaListAsset);
    }

    /**
    *@dev allows exchange contract to assign address to index in when deleting from array
    */
    function setOpenDdaListAssetByIndex(uint _indexToDelete, address _lastAdd) public onlyDex {
        openDdaListAssets[_indexToDelete]=_lastAdd;
    }
    /**
    *@dev allows exchange contract to assign index to address when deleting from array
    */
    function setOpenDdaListIndex(address _ddaListAsset, uint _value) public onlyDex {
        openDdaListIndex[_ddaListAsset]= _value ;
    }

    function setOpenDdaArrayLength() public onlyDex{
        openDdaListAssets.length--;
    }
    /**
    *@dev Sets the DDA List Asset information for the specifed 
    *asset address
    *@param _asset address 
    *@param _amount of asset
    *@param _price uint256 price per unit in wei
    *@param _isLong true if it is long
    *@return price, amount and true if isLong
    */
    function setDdaListAssetInfoAll(ListAsset storage list, address _assetAddress, uint _price, uint _amount, bool _isLong) public onlyDex {
        ListAsset storage listing = listOfAssets[_assetAddress];
        listing.price = _price;
        listing.amount= _amount;
        listing.isLong= _isLong;
    }

    function setDdaListAssetInfoAmount(address _assetAddress, uint _amount) public onlyDex {
        ListAsset storage listing = listOfAssets[_assetAddress];
        listing.amount= _amount;
    }


    /**
    *@dev Adds to open orderbooks
    *@return _uint of the number of tokens with open orders
    */
    function setOpenBooks(address _openBookAdd) public onlyDex {
        openBooks.push(_openBookAdd);
    }

    //use the nonce for orderId
    function setOrder(uint256 _orderId, address _maker, uint256 _price,uint256 _amount, address _tokenadd) public  {
        Order storage _order = orders[_orderId];
        _order.maker = _maker;
        _order.price = _price;
        _order.amount = _amount;
        _order.asset = _tokenadd;
    }

    function setForSale(address _tokenadd, uint _order_nonce) public {
        forSale[_tokenadd].push(_order_nonce);
    }

    function setForSaleIndex(uint _order_nonce, uint _order_count) public onlyDex {
        forSaleIndex[_order_nonce]= _order_count;
    }

    function setOpenBookIndex(address _order, uint _order_index) public onlyDex {
        openBookIndex[_order]= _order_index;
    }

    function setUserOrders(address _user, uint _order_nonce) public onlyDex {
        userOrders[_user].push(_order_nonce);
    }

    function setUserOrderIndex(address _user, uint _order_nonce) public onlyDex {
        userOrderIndex[_order_nonce] = userOrders[_user].length;
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
    *@dev An internal function to update mappings when an order is removed from the book
    *@param _orderId is the uint256 ID of order
    *@param _order is the struct containing the details of the order
    */
     function unLister(uint256 _orderId, Order _order) public onlyDex {
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
    } 

}
