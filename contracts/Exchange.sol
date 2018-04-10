pragma solidity ^0.4.18;

 import "./libraries/SafeMath.sol";
 import "./interfaces/ERC20_Interface.sol";

/**
*@To do:
Allow partial fills
*/
contract Exchange{
    using SafeMath for uint256;

    /***VARIABLES***/
    address public owner; //The owner of the market contract
    
    /***DATA***/
    //This is the base data structure for an order (the maker of the order and the price)
    struct Order {
        address maker;// the placer of the order
        uint price;// The price in wei
        uint amount;
        address asset;
    }

    //Maps an OrderID to the list of orders
    mapping(uint256 => Order) public orders;
    //An mapping of a token address to the orderID's
    mapping(address =>  uint256[]) public forSale;
    //Index telling where a specific tokenId is in the forSale array
    mapping(uint256 => uint256) forSaleIndex;
    //Index telling where a specific tokenId is in the forSale array
    address[] public openBooks;
    //mapping of address to position in openBooks
    mapping (address => uint) openBookIndex;
    //mapping of user to their orders
    mapping(address => uint[]) userOrders;
    //mapping from orderId to userOrder position
    mapping(uint => uint) userOrderIndex;
    //A list of the blacklisted addresses
    mapping(address => bool) blacklist;
    //order_nonce;
    uint order_nonce;

    /***MODIFIERS***/
    /// @dev Access modifier for Owner functionality
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /***EVENTS***/
    event OrderPlaced(address _token, uint256 _amount, uint256 _price);
    event Sale(address _token, uint256 _amount, uint256 _price);
    event OrderRemoved(address _token, uint256 _amount, uint256 _price);

    /***FUNCTIONS***/
    /*
    *@dev the constructor argument to set the owner and initialize the array.
    */
    function Exchange() public{
        owner = msg.sender;
        openBooks.push(address(0));
        order_nonce = 0;
    }

    /*
    *@dev The fallback function to prevent money from being sent to the contract
    */
    function()  payable public{
        require(msg.value == 0);
    }

    /*
    *@dev listPhoto allows a party to place a photo on the orderbook
    *@param _tokenId uint256 ID of photo
    *@param _price uint256 price of photo in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require(blacklist[msg.sender] == false);
        require(_price > 0);
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(token.transferFrom(msg.sender,address(this),_amount));
        if(forSale[_tokenadd].length == 0){
            forSale[_tokenadd].push(0);
            }
        forSaleIndex[order_nonce] = forSale[_tokenadd].length;
        forSale[_tokenadd].push(order_nonce);
        orders[order_nonce] = Order({
            maker: msg.sender,
            price: _price,
            amount:_amount,
            asset: _tokenadd
        });
        OrderPlaced(_tokenadd,_amount,_price);
        if(openBookIndex[_tokenadd] == 0 ){    
            openBookIndex[_tokenadd] = openBooks.length;
            openBooks.push(_tokenadd);
        }
        userOrderIndex[order_nonce] = userOrders[msg.sender].length;
        userOrders[msg.sender].push(order_nonce);
        order_nonce += 1;
    }
    /**
    *@dev unlistPhoto allows a party to remove their order from the orderbook
    *@param _tokenId uint256 ID of photo
    */
    function unlist(uint256 _orderId) external{
        require(forSaleIndex[_orderId] > 0);
        Order memory _order = orders[_orderId];
        require(msg.sender== _order.maker || msg.sender == owner);
        unLister(_orderId);
        ERC20_Interface token = ERC20_Interface(_order.asset);
        token.transferFrom(address(this),msg.sender,_order.amount);
        OrderRemoved(_order.asset,_order.amount,_order.price);
    }

    /**
    *@dev buyPhoto allows a party to send Ether to buy a photo off of the orderbook
    *@param _tokenId uint256 ID of photo
    */
    function buy(uint256 _orderId) external payable {
        Order memory _order = orders[_orderId];
        require(msg.value == _order.price);
        require(blacklist[msg.sender] == false);
        address maker = _order.maker;
        ERC20_Interface token = ERC20_Interface(_order.asset);
        token.transferFrom(address(this),msg.sender, _order.amount);
        unLister(_orderId);
        maker.transfer(_order.price);
        Sale(_order.asset,_order.amount,_order.price);
    }

    /*
    *@dev getOrder lists the price and maker of a specific token for a sale
    *@param _tokenId uint256 ID of photo
    *@return address of the party selling the rights to the photo
    *@return uint of the price of the sale
    */
    function getOrder(uint256 _orderId) external view returns(address,uint,uint){
        Order storage _order = orders[_orderId];
        return (_order.maker,_order.price,_order.amount);
    }

    /*
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
    }

    /*
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    *@Note - This allows the owner to stop a malicious party from spamming the orderbook
    */
    function blacklistParty(address _address, bool _motion) public onlyOwner() {
        blacklist[_address] = _motion;
    }

    /*
    *@dev Allows parties to see if one is blacklisted
    *@param _address the address of the party to blacklist
    *@return bool, true for is blacklisted
    */
    function isBlacklist(address _address) public view returns(bool) {
        return blacklist[_address];
    }

    /*
    *@dev getOrderCount allows parties to query how many orders are on the book
    *@return _uint of the number of orders in the orderbook
    */
    function getOrderCount(address _token) public constant returns(uint) {
        return forSale[_token].length;
    }

    /*
    *@dev allows owner to withdraw funds
    */
    function withdraw() public onlyOwner(){
        owner.transfer(this.balance);
    }


    /***INTERNAL FUNCTIONS***/
    /*
    *@dev An internal function to update mappings when an order is removed from the book
    *@param _tokenId uint256 ID of photo
    */
    function unLister(uint256 _orderId) internal{
        Order memory _order = orders[_orderId];

        uint256 tokenIndex = forSaleIndex[_orderId];
        uint256 lastTokenIndex = forSale[_order.asset].length.sub(1);
        uint256 lastToken = forSale[_order.asset][lastTokenIndex];
        forSale[_order.asset][tokenIndex] = lastToken;
        forSaleIndex[lastToken] = tokenIndex;
        forSale[_order.asset].length--;
        forSaleIndex[_orderId] = 0;
        orders[_orderId] = Order({
            maker: address(0),
            price: 0,
            amount:0,
            asset: address(0)
        });
        if(forSale[_order.asset].length == 1){
            tokenIndex = openBookIndex[_order.asset];
            lastTokenIndex = openBooks.length.sub(1);
            address lastAdd = openBooks[lastTokenIndex];
            openBooks[tokenIndex] = lastAdd;
            openBookIndex[lastAdd] = tokenIndex;
            openBooks.length--;
            openBookIndex[_order.asset] = 0;
        }
        tokenIndex = userOrderIndex[_orderId];
        lastTokenIndex = userOrders[_order.maker].length.sub(1);
        lastToken = userOrders[_order.maker][lastTokenIndex];
        userOrders[_order.maker][tokenIndex] = lastToken;
        userOrderIndex[lastToken] = tokenIndex;
        userOrders[_order.maker].length--;
        userOrderIndex[_orderId] = 0;
    }
}