pragma solidity ^0.4.24;

/**
*This contracts helps clone factories and swaps through the Deployer.sol and MasterDeployer.sol.
*The address of the targeted contract to clone has to be provided.
*/
contract CloneFactory {

    /*Variables*/
    address internal owner;
    
    /*Events*/
    event CloneCreated(address indexed target, address clone);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }    
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _owner the new owner address
    */
    function setOwner(address _owner) public onlyOwner(){
        owner = _owner;
    }

    /**
    *@dev Creates factory clone
    *@param _target is the address being cloned
    *@return address for clone
    */
    function createClone(address target) internal returns (address result) {
        bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
        bytes20 targetBytes = bytes20(target);
        for (uint i = 0; i < 20; i++) {
            clone[26 + i] = targetBytes[i];
        }
        assembly {
            let len := mload(clone)
            let data := add(clone, 0x20)
            result := create(0, data, len)
        }
    }
}

/**
*Swap Deployer Contract - purpose is to save gas for deployment of Factory contract.
*It ensures only the factory can create new contracts and uses CloneFactory to clone 
*the swap specified.
*/

contract Deployer is CloneFactory {
    /*Variables*/
    address internal factory;
    address public swap;
    
    /*Events*/
    event Deployed(address indexed master, address indexed clone);

    /*Functions*/
    /**
    *@dev Deploys the factory contract and swap address
    *@param _factory is the address of the factory contract
    */    
    constructor(address _factory) public {
        factory = _factory;
        swap = new TokenToTokenSwap(address(this),msg.sender,address(this),now);
    }

    /**
    *@dev Set swap address to clone
    *@param _addr swap address to clone
    */
    function updateSwap(address _addr) public onlyOwner() {
        swap = _addr;
    }
        
    /**
    *@notice The function creates a new contract
    *@dev It ensures the new contract can only be created by the factory
    *@param _party address of user creating the contract
    *@param user_contract address of userContract.sol 
    *@param _start_date contract start date
    *@return returns the address for the new contract
    */
    function newContract(address _party, address _user, uint _start) public returns (address) {
        address new_swap = createClone(swap);
        TokenToTokenSwap(new_swap).init(factory, _party, _user, _start);
        emit Deployed(swap, new_swap);
        return new_swap;
    }

    /**
    *@dev Set variables if the owner is the factory contract
    *@param _factory address
    *@param _owner address
    */
    function setVars(address _factory, address _owner) public {
        require (msg.sender == owner);
        factory = _factory;
        owner = _owner;
    }
}

/**
*The DRCT_Token is an ERC20 compliant token representing the payout of the swap contract
*specified in the Factory contract.
*Each Factory contract is specified one DRCT Token and the token address can contain many
*different swap contracts that are standardized at the Factory level.
*The logic for the functions in this contract is housed in the DRCTLibary.sol.
*/
contract DRCT_Token {

    using DRCTLibrary for DRCTLibrary.TokenStorage;

    /*Variables*/
    DRCTLibrary.TokenStorage public drct;
    string public constant name = "DRCT Token";
    string public constant symbol = "DRCT";

    /*Functions*/
    /**
    *@dev Constructor - sets values for token name and token supply, as well as the 
    *factory_contract, the swap.
    *@param _factory 
    */
    constructor() public {
        drct.startToken(msg.sender);
    }

    /**
    *@dev Token Creator - This function is called by the factory contract and creates new tokens
    *for the user
    *@param _supply amount of DRCT tokens created by the factory contract for this swap
    *@param _owner address
    *@param _swap address
    */
    function createToken(uint _supply, address _owner, address _swap) public{
        drct.createToken(_supply,_owner,_swap);
    }

    /**
    *@dev gets the factory address
    */
    function getFactoryAddress() external view returns(address){
        return drct.getFactoryAddress();
    }

    /**
    *@dev Called by the factory contract, and pays out to a _party
    *@param _party being paid
    *@param _swap address
    */
    function pay(address _party, address _swap) public{
        drct.pay(_party,_swap);
    }

    /**
    *@dev Returns the users total balance (sum of tokens in all swaps the user has tokens in)
    *@param _owner user address
    *@return user total balance
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
       return drct.balanceOf(_owner);
     }

    /**
    *@dev Getter for the total_supply of tokens in the contract
    *@return total supply
    */
    function totalSupply() public constant returns (uint _total_supply) {
       return drct.totalSupply();
    }

    /**
    *ERC20 compliant transfer function
    *@param _to Address to send funds to
    *@param _amount Amount of token to send
    *@return true for successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        return drct.transfer(_to,_amount);
    }

    /**
    *@dev ERC20 compliant transferFrom function
    *@param _from address to send funds from (must be allowed, see approve function)
    *@param _to address to send funds to
    *@param _amount amount of token to send
    *@return true for successful transfer
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        return drct.transferFrom(_from,_to,_amount);
    }

    /**
    *@dev ERC20 compliant approve function
    *@param _spender party that msg.sender approves for transferring funds
    *@param _amount amount of token to approve for sending
    *@return true for successful
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        return drct.approve(_spender,_amount);
    }

    /**
    *@dev Counts addresses involved in the swap based on the length of balances array for _swap
    *@param _swap address
    *@return the length of the balances array for the swap
    */
    function addressCount(address _swap) public constant returns (uint) { 
        return drct.addressCount(_swap); 
    }

    /**
    *@dev Gets the owner address and amount by specifying the swap address and index
    *@param _ind specified index in the swap
    *@param _swap specified swap address
    *@return the amount to transfer associated with a particular index in a particular swap
    *@return the owner address associated with a particular index in a particular swap
    */
    function getBalanceAndHolderByIndex(uint _ind, address _swap) public constant returns (uint, address) {
        return drct.getBalanceAndHolderByIndex(_ind,_swap);
    }

    /**
    *@dev Gets the index by specifying the swap and owner addresses
    *@param _owner specifed address
    *@param _swap  specified swap address
    *@return the index associated with the _owner address in a particular swap
    */
    function getIndexByAddress(address _owner, address _swap) public constant returns (uint) {
        return drct.getIndexByAddress(_owner,_swap); 
    }

    /**
    *@dev Look up how much the spender or contract is allowed to spend?
    *@param _owner address
    *@param _spender party approved for transfering funds 
    *@return the allowed amount _spender can spend of _owner's balance
    */
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return drct.allowance(_owner,_spender); 
    }
}

/**
*Exchange creates an exchange for the swaps.
*/
contract Exchange{ 
    using SafeMath for uint256;

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
        openBooks.push(address(0));
        order_nonce = 1;
    }

    /**
    *@dev list allows a party to place an order on the orderbook
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require(blacklist[msg.sender] == false);
        require(_price > 0);
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(token.allowance(msg.sender,address(this)) >= _amount);
        if(forSale[_tokenadd].length == 0){
            forSale[_tokenadd].push(0);
            }
        forSaleIndex[order_nonce] = forSale[_tokenadd].length;
        forSale[_tokenadd].push(order_nonce);
        orders[order_nonce] = Order({
            maker: msg.sender,
            asset: _tokenadd,
            price: _price,
            amount:_amount
        });
        emit OrderPlaced(msg.sender,_tokenadd,_amount,_price);
        if(openBookIndex[_tokenadd] == 0 ){    
            openBookIndex[_tokenadd] = openBooks.length;
            openBooks.push(_tokenadd);
        }
        userOrderIndex[order_nonce] = userOrders[msg.sender].length;
        userOrders[msg.sender].push(order_nonce);
        order_nonce += 1;
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
        require(blacklist[msg.sender] == false);
        ListAsset storage listing = listOfAssets[_asset];
        listing.price = _price;
        listing.amount= _amount;
        listing.isLong= _isLong;
        openDdaListIndex[_asset] = openDdaListAssets.length;
        openDdaListAssets.push(_asset);
        
    }

    /**
    *@dev list allows a DDA to remove asset 
    *@param _asset address 
    */
    function unlistDda(address _asset) public onlyOwner() {
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
    }

    /**
    *@dev buy allows a party to partially fill an order
    *@param _asset is the address of the assset listed
    *@param _amount is the amount of tokens to buy
    */
    function buyPerUnit(address _asset, uint256 _amount) external payable {
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
    }

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
    function unlist(uint256 _orderId) external{
        require(forSaleIndex[_orderId] > 0);
        Order memory _order = orders[_orderId];
        require(msg.sender== _order.maker || msg.sender == owner);
        unLister(_orderId,_order);
        emit OrderRemoved(msg.sender,_order.asset,_order.amount,_order.price);
    }

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
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

    /**
    *@dev allows the owner to change who the owner is
    *@param _owner is the address of the new owner
    */
    function setOwner(address _owner) public onlyOwner() {
        owner = _owner;
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
    /**
    *@dev An internal function to update mappings when an order is removed from the book
    *@param _orderId is the uint256 ID of order
    *@param _order is the struct containing the details of the order
    */
    function unLister(uint256 _orderId, Order _order) internal{
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


/**
*The Factory contract sets the standardized variables and also deploys new contracts based on
*these variables for the user.  
*/
contract Factory {
    using SafeMath for uint256;
    
    /*Variables*/
    //Addresses of the Factory owner and oracle. For oracle information, 
    //check www.github.com/DecentralizedDerivatives/Oracles
    address public owner;
    address public oracle_address;
    //Address of the user contract
    address public user_contract;
    //Address of the deployer contract
    address internal deployer_address;
    Deployer_Interface internal deployer;
    address public token;
    //A fee for creating a swap in wei.  Plan is for this to be zero, however can be raised to prevent spam
    uint public fee;
    //swap fee
    uint public swapFee;
    //Duration of swap contract in days
    uint public duration;
    //Multiplier of reference rate.  2x refers to a 50% move generating a 100% move in the contract payout values
    uint public multiplier;
    //Token_ratio refers to the number of DRCT Tokens a party will get based on the number of base tokens.  As an example, 1e15 indicates that a party will get 1000 DRCT Tokens based upon 1 ether of wrapped wei. 
    uint public token_ratio;
    //Array of deployed contracts
    address[] public contracts;
    uint[] public startDates;
    address public memberContract;
    uint whitelistedTypes;
    mapping(address => uint) public created_contracts;
    mapping(address => uint) public token_dates;
    mapping(uint => address) public long_tokens;
    mapping(uint => address) public short_tokens;
    mapping(address => uint) public token_type; //1=short 2=long

    /*Events*/
    //Emitted when a Swap is created
    event ContractCreation(address _sender, address _created);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev Sets the member type/permissions for those whitelisted and owner
    *@param _memberTypes is the list of member types
    */
     constructor(uint _memberTypes) public {
        owner = msg.sender;
        whitelistedTypes=_memberTypes;
    }

    /**
    *@dev constructor function for cloned factory
    */
    function init(address _owner, uint _memberTypes) public{
        require(owner == address(0));
        owner = _owner;
        whitelistedTypes=_memberTypes;
    }

    /**
    *@dev Sets the Membership contract address
    *@param _memberContract The new membership address
    */
    function setMemberContract(address _memberContract) public onlyOwner() {
        memberContract = _memberContract;
    }


    /**
    *@dev Checks the membership type/permissions for whitelisted members
    *@param _member address to get membership type from
    */
    function isWhitelisted(address _member) public view returns (bool){
        Membership_Interface Member = Membership_Interface(memberContract);
        return Member.getMembershipType(_member)>= whitelistedTypes;
    }
 
    /**
    *@dev Gets long and short token addresses based on specified date
    *@param _date 
    *@return short and long tokens' addresses
    */
    function getTokens(uint _date) public view returns(address, address){
        return(long_tokens[_date],short_tokens[_date]);
    }

    /**
    *@dev Gets the type of Token (long and short token) for the specifed 
    *token address
    *@param _token address 
    *@return token type short = 1 and long = 2
    */
    function getTokenType(address _token) public view returns(uint){
        return(token_type[_token]);
    }

    /**
    *@dev Updates the fee amount
    *@param _fee is the new fee amount
    */
    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

    /**
    *@dev Updates the swap fee amount
    *@param _swapFee is the new swap fee amount
    */
    function setSwapFee(uint _swapFee) public onlyOwner() {
        swapFee = _swapFee;
    }   

    /**
    *@dev Sets the deployer address
    *@param _deployer is the new deployer address
    */
    function setDeployer(address _deployer) public onlyOwner() {
        deployer_address = _deployer;
        deployer = Deployer_Interface(_deployer);
    }

    /**
    *@dev Sets the user_contract address
    *@param _userContract is the new userContract address
    */
    function setUserContract(address _userContract) public onlyOwner() {
        user_contract = _userContract;
    }

    /**
    *@dev Sets token ratio, swap duration, and multiplier variables for a swap.
    *@param _token_ratio the ratio of the tokens
    *@param _duration the duration of the swap, in days
    *@param _multiplier the multiplier used for the swap
    *@param _swapFee the swap fee
    */
    function setVariables(uint _token_ratio, uint _duration, uint _multiplier, uint _swapFee) public onlyOwner() {
        require(_swapFee < 10000);
        token_ratio = _token_ratio;
        duration = _duration;
        multiplier = _multiplier;
        swapFee = _swapFee;
    }

    /**
    *@dev Sets the address of the base tokens used for the swap
    *@param _token The address of a token to be used  as collateral
    */
    function setBaseToken(address _token) public onlyOwner() {
        token = _token;
    }

    /**
    *@dev Allows a user to deploy a new swap contract, if they pay the fee
    *@param _start_date the contract start date 
    *@pararm _user your address if calling it directly.  Allows you to create on behalf of someone
    *@return new_contract address for he newly created swap address and calls 
    *event 'ContractCreation'
    */
    function deployContract(uint _start_date,address _user) public payable returns (address) {
        require(msg.value >= fee && isWhitelisted(_user));
        require(_start_date % 86400 == 0);
        address new_contract = deployer.newContract(_user, user_contract, _start_date);
        contracts.push(new_contract);
        created_contracts[new_contract] = _start_date;
        emit ContractCreation(_user,new_contract);
        return new_contract;
    }

    /**
    *@dev Deploys DRCT tokens for given start date
    *@param _start_date of contract
    */
    function deployTokenContract(uint _start_date) public{
        address _token;
        require(_start_date % 86400 == 0);
        require(long_tokens[_start_date] == address(0) && short_tokens[_start_date] == address(0));
        _token = new DRCT_Token();
        token_dates[_token] = _start_date;
        long_tokens[_start_date] = _token;
        token_type[_token]=2;
        _token = new DRCT_Token();
        token_type[_token]=1;
        short_tokens[_start_date] = _token;
        token_dates[_token] = _start_date;
        startDates.push(_start_date);

    }

    /**
    *@dev Deploys new tokens on a DRCT_Token contract -- called from within a swap
    *@param _supply The number of tokens to create
    *@param _party the address to send the tokens to
    *@param _start_date the start date of the contract      
    *@returns ltoken the address of the created DRCT long tokens
    *@returns stoken the address of the created DRCT short tokens
    *@returns token_ratio The ratio of the created DRCT token
    */
    function createToken(uint _supply, address _party, uint _start_date) public returns (address, address, uint) {
        require(created_contracts[msg.sender] == _start_date);
        address ltoken = long_tokens[_start_date];
        address stoken = short_tokens[_start_date];
        require(ltoken != address(0) && stoken != address(0));
            DRCT_Token drct_interface = DRCT_Token(ltoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
            drct_interface = DRCT_Token(stoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
        return (ltoken, stoken, token_ratio);
    }
  
    /**
    *@dev Allows the owner to set a new oracle address
    *@param _new_oracle_address 
    */
    function setOracleAddress(address _new_oracle_address) public onlyOwner() {
        oracle_address = _new_oracle_address; 
    }

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Allows the owner to pull contract creation fees
    *@return the withdrawal fee _val and the balance where is the return function?
    */
    function withdrawFees() public onlyOwner(){
        Wrapped_Ether_Interface token_interface = Wrapped_Ether_Interface(token);
        uint _val = token_interface.balanceOf(address(this));
        if(_val > 0){
            token_interface.withdraw(_val);
        }
        owner.transfer(address(this).balance);
     }

    /**
    *@dev fallback function
    */ 
    function() public payable {
    }

    /**
    *@dev Returns a tuple of many private variables.
    *The variables from this function are pass through to the TokenLibrary.getVariables function
    *@returns oracle_adress is the address of the oracle
    *@returns duration is the duration of the swap
    *@returns multiplier is the multiplier for the swap
    *@returns token is the address of token
    *@returns _swapFee is the swap fee 
    */
    function getVariables() public view returns (address, uint, uint, address,uint){
        return (oracle_address,duration, multiplier, token,swapFee);
    }

    /**
    *@dev Pays out to a DRCT token
    *@param _party is the address being paid
    *@param _token_add token to pay out
    */
    function payToken(address _party, address _token_add) public {
        require(created_contracts[msg.sender] > 0);
        DRCT_Token drct_interface = DRCT_Token(_token_add);
        drct_interface.pay(_party, msg.sender);
    }

    /**
    *@dev Counts number of contacts created by this factory
    *@return the number of contracts
    */
    function getCount() public constant returns(uint) {
        return contracts.length;
    }

    /**
    *@dev Counts number of start dates in this factory
    *@return the number of active start dates
    */
    function getDateCount() public constant returns(uint) {
        return startDates.length;
    }
}

/**
*This contract deploys a factory contract and uses CloneFactory to clone the factory
*specified.
*/

contract MasterDeployer is CloneFactory{
    
    using SafeMath for uint256;

    /*Variables*/
    address[] factory_contracts;
    address private factory;
    mapping(address => uint) public factory_index;

    /*Events*/
    event NewFactory(address _factory);

    /*Functions*/
    /**
    *@dev Initiates the factory_contract array with address(0)
    */
    constructor() public {
        factory_contracts.push(address(0));
    }

    /**
    *@dev Set factory address to clone
    *@param _factory address to clone
    */  
    function setFactory(address _factory) public onlyOwner(){
        factory = _factory;
    }

    /**
    *@dev creates a new factory by cloning the factory specified in setFactory.
    *@return _new_fac which is the new factory address
    */
    function deployFactory(uint _memberTypes) public onlyOwner() returns(address){
        address _new_fac = createClone(factory);
        factory_index[_new_fac] = factory_contracts.length;
        factory_contracts.push(_new_fac);
        Factory(_new_fac).init(msg.sender,_memberTypes);
        emit NewFactory(_new_fac);
        return _new_fac;
    }

    /**
    *@dev Removes the factory specified
    *@param _factory address to remove
    */
    function removeFactory(address _factory) public onlyOwner(){
        require(_factory != address(0) && factory_index[_factory] != 0);
        uint256 fIndex = factory_index[_factory];
        uint256 lastFactoryIndex = factory_contracts.length.sub(1);
        address lastFactory = factory_contracts[lastFactoryIndex];
        factory_contracts[fIndex] = lastFactory;
        factory_index[lastFactory] = fIndex;
        factory_contracts.length--;
        factory_index[_factory] = 0;
    }

    /**
    *@dev Counts the number of factories
    *@returns the number of active factories
    */
    function getFactoryCount() public constant returns(uint){
        return factory_contracts.length - 1;
    }

    /**
    *@dev Returns the factory address for the specified index
    *@param _index for factory to look up in the factory_contracts array
    *@return factory address for the index specified
    */
    function getFactorybyIndex(uint _index) public constant returns(address){
        return factory_contracts[_index];
    }
}

/**
*This contract allows users to sign up for the DDA Cooperative Membership.
*To complete membership DDA will provide instructions to complete KYC/AML verification
*through a system external to this contract.
*/
contract Membership {
    using SafeMath for uint256;
    
    /*Variables*/
    address public owner;
    //Memebership fees
    uint public memberFee;

    /*Structs*/
    /**
    *@dev Keeps member information 
    */
    struct Member {
        uint memberId;
        uint membershipType;
    }
    
    /*Mappings*/
    //Members information
    mapping(address => Member) public members;
    address[] public membersAccts;
    mapping (address => uint) public membersAcctsIndex;

    /*Events*/
    event UpdateMemberAddress(address _from, address _to);
    event NewMember(address _address, uint _memberId, uint _membershipType);
    event Refund(address _address, uint _amount);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
     constructor() public {
        owner = msg.sender;
    }

    /*
    *@dev Updates the fee amount
    *@param _memberFee fee amount for member
    */
    function setFee(uint _memberFee) public onlyOwner() {
        //define fee structure for the three membership types
        memberFee = _memberFee;
    }
    
    /**
    *@notice Allows a user to become DDA members if they pay the fee. However, they still have to complete
    *complete KYC/AML verification off line
    *@dev This creates and transfers the token to the msg.sender
    */
    function requestMembership() public payable {
        Member storage sender = members[msg.sender];
        require(msg.value >= memberFee && sender.membershipType == 0 );
        membersAcctsIndex[msg.sender] = membersAccts.length;
        membersAccts.push(msg.sender);
        sender.memberId = membersAccts.length;
        sender.membershipType = 1;
        emit NewMember(msg.sender, sender.memberId, sender.membershipType);
    }
    
    /**
    *@dev This updates/transfers the member address 
    *@param _from is the current member address
    *@param _to is the address the member would like to update their current address with
    */
    function updateMemberAddress(address _from, address _to) public onlyOwner {
        require(_to != address(0));
        Member storage currentAddress = members[_from];
        Member storage newAddress = members[_to];
        require(newAddress.memberId == 0);
        newAddress.memberId = currentAddress.memberId;
        newAddress.membershipType = currentAddress.membershipType;
        membersAccts[currentAddress.memberId - 1] = _to;
        currentAddress.memberId = 0;
        currentAddress.membershipType = 0;
        emit UpdateMemberAddress(_from, _to);
    }

    /**
    *@dev Use this function to set membershipType for the member
    *@param _memberAddress address of member that we need to update membershipType
    *@param _membershipType type of membership to assign to member
    */
    function setMembershipType(address _memberAddress,  uint _membershipType) public onlyOwner{
        Member storage memberAddress = members[_memberAddress];
        memberAddress.membershipType = _membershipType;
    }

    /**
    *@dev Use this function to set memberId for the member
    *@param _memberAddress address of member that we need to update membershipType
    *@param _memberId is the manually assigned memberId
    */
    function setMemberId(address _memberAddress,  uint _memberId) public onlyOwner{
        Member storage memberAddress = members[_memberAddress];
        memberAddress.memberId = _memberId;
    }

    /**
    *@dev Use this function to remove member acct from array memberAcct
    *@param _memberAddress address of member to remove
    */
    function removeMemberAcct(address _memberAddress) public onlyOwner{
        require(_memberAddress != address(0));
        uint256 indexToDelete;
        uint256 lastAcctIndex;
        address lastAdd;
        Member storage memberAddress = members[_memberAddress];
        memberAddress.memberId = 0;
        memberAddress.membershipType = 0;
        indexToDelete = membersAcctsIndex[_memberAddress];
        lastAcctIndex = membersAccts.length.sub(1);
        lastAdd = membersAccts[lastAcctIndex];
        membersAccts[indexToDelete]=lastAdd;
        membersAcctsIndex[lastAdd] = indexToDelete;   
        membersAccts.length--;
        membersAcctsIndex[_memberAddress]=0; 
    }


    /**
    *@dev Use this function to member acct from array memberAcct
    *@param _memberAddress address of member to add
    */
    function addMemberAcct(address _memberAddress) public onlyOwner{
        require(_memberAddress != address(0));
        Member storage memberAddress = members[_memberAddress];
        membersAcctsIndex[_memberAddress] = membersAccts.length; 
        membersAccts.push(_memberAddress);
        memberAddress.memberId = membersAccts.length;
        memberAddress.membershipType = 1;
        emit NewMember(_memberAddress, memberAddress.memberId, memberAddress.membershipType);
    }

    /**
    *@dev getter function to get all membersAccts
    */
    function getMembers() view public returns (address[]){
        return membersAccts;
    }
    
    /**
    *@dev Get member information
    *@param _memberAddress address to pull the memberId, membershipType and membership
    */
    function getMember(address _memberAddress) view public returns(uint, uint) {
        return(members[_memberAddress].memberId, members[_memberAddress].membershipType);
    }

    /**
    *@dev Gets length of array containing all member accounts or total supply
    */
    function countMembers() view public returns(uint) {
        return membersAccts.length;
    }

    /**
    *@dev Gets membership type
    *@param _memberAddress address to view the membershipType
    */
    function getMembershipType(address _memberAddress) public constant returns(uint){
        return members[_memberAddress].membershipType;
    }
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Refund money if KYC/AML fails
    *@param _to address to send refund
    *@param _amount to refund. If no amount  is specified the current memberFee is refunded
    */
    function refund(address _to, uint _amount) public onlyOwner {
        require (_to != address(0));
        if (_amount == 0) {_amount = memberFee;}
        removeMemberAcct(_to);
        _to.transfer(_amount);
        emit Refund(_to, _amount);
    }

    /**
    *@dev Allow owner to withdraw funds
    *@param _to address to send funds
    *@param _amount to send
    */
    function withdraw(address _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }    
}

contract Migrations {

    /*Variables*/
    address public owner;
    uint public last_completed_migration;

    /*Modifiers*/
    modifier restricted() {
        if (msg.sender == owner) 
        _;
    }

    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */    
     constructor() public {
        owner = msg.sender;
    }

    /**
    *@dev Resets last_completed_migration to latest completed migration
    *@param completed unix date as uint for last completed migration? gobal variable?
    */ 
    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    /**
    @param new_address is the new address
    */
    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}

/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/

contract Oracle is usingOraclize{
    /*Variables*/
    //Private queryId for Oraclize callback
    bytes32 private queryID;
    string public API;
    string public API2;
    string public usedAPI;

    /*Structs*/
    struct QueryInfo {
        uint value;
        bool queried;
        uint date;
        uint calledTime;
        bool called;
    }  
    //Mapping of documents stored in the oracle
    mapping(uint => bytes32) public queryIds;
    mapping(bytes32 => QueryInfo ) public info;

    /*Events*/
    event DocumentStored(uint _key, uint _value);
    event newOraclizeQuery(string description);

    /*Functions*/
    /**
    *@dev Constructor, sets two public api strings
    *e.g. "json(https://api.gdax.com/products/BTC-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
    * or "json(https://api.gdax.com/products/ETH-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
    */
     constructor(string _api, string _api2) public{
        API = _api;
        API2 = _api2;
    }

    /**
    *@dev RetrieveData - Returns stored value by given key
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    */
    function retrieveData(uint _date) public constant returns (uint) {
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.value;
    }

    /**
    *@dev PushData - Sends an Oraclize query for entered API
    */
    function pushData() public payable{
        uint _key = now - (now % 86400);
        uint _calledTime = now;
        QueryInfo storage currentQuery = info[queryIds[_key]];
        require(currentQuery.queried == false  && currentQuery.calledTime == 0 || 
            currentQuery.calledTime != 0 && _calledTime >= (currentQuery.calledTime + 3600) &&
            currentQuery.value == 0);
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize queries sent");
            if (currentQuery.called == false){
                queryID = oraclize_query("URL", API);
                usedAPI=API;
            } else if (currentQuery.called == true ){
                queryID = oraclize_query("URL", API2);
                usedAPI=API2;  
            }

            queryIds[_key] = queryID;
            currentQuery = info[queryIds[_key]];
            currentQuery.queried = true;
            currentQuery.date = _key;
            currentQuery.calledTime = _calledTime;
            currentQuery.called = !currentQuery.called;
        }
    }

    /*
    * gets API used for tests
    */
    function getusedAPI() public view returns(string){
        return usedAPI;
    }
    
    /**
    *@dev Used by Oraclize to return value of PushData API call
    *@param _oraclizeID unique oraclize identifier of call
    *@param _result Result of API call in string format
    */
    function __callback(bytes32 _oraclizeID, string _result) public {
        QueryInfo storage currentQuery = info[_oraclizeID];
        require(msg.sender == oraclize_cbAddress() && _oraclizeID == queryID);
        currentQuery.value = parseInt(_result,3);
        currentQuery.called = false; 
        if(currentQuery.value == 0){
            currentQuery.value = 1;
        }
        emit DocumentStored(currentQuery.date, currentQuery.value);
    }

    /**
    *@dev Allows the contract to be funded in order to pay for oraclize calls
    */
    function fund() public payable {
      
    }

    /**
    *@dev Determine if the Oracle was queried
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    *@return true or false based upon whether an API query has been 
    *initialized (or completed) for given date
    */
    function getQuery(uint _date) public view returns(bool){
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.queried;
    }
}

/**
*The Oracle contract provides the reference prices for the contracts.  Currently the Oracle is 
*updated by an off chain calculation by DDA.  Methodology can be found at 
*www.github.com/DecentralizedDerivatives/Oracles
*/
contract Test_Oracle {

    /*Variables*/
    //Owner of the oracle
    address private owner;
    string public API;
    //Mapping of documents stored in the oracle
    mapping(uint => uint) internal oracle_values;
    mapping(uint => bool) public queried;

    /*Events*/
    event DocumentStored(uint _key, uint _value);

    /*Modifiers*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
    *@dev Constructor - Sets owner
    */
     constructor(string _api) public {
        owner = msg.sender;
        API = _api;
    }

    /**
    *@dev Allows the owner of the Oracle to store a document in the oracle_values mapping. Documents
    *represent underlying values at a specified date (key).
    */
    function StoreDocument(uint _key, uint _value) public onlyOwner() {
        if(_value == 0){
            _value = 1;
        }
        oracle_values[_key] = _value;
        emit DocumentStored(_key, _value);
        queried[_key] = true;
    }

    function pushData() public pure {
        //here for testing purposes
    }

    /**
    *@dev Determine if the Oracle was queried
    *@param _date a specified date
    *@return whether or not the Oracle was queried on the specified date
    */    
    function getQuery(uint _date) public view returns(bool){
        return queried[_date];
    }

    /**
    *@dev Allows for the viewing of Oracle data
    *@param _date specified date being queried from the Oracle data
    *@return oracle_values for the date
    */
    function retrieveData(uint _date) public constant returns (uint) {
        return oracle_values[_date];
    }

    /**
    *@dev Set the new owner of the contract or test oracle?
    *@param _new_owner for the oracle? 
    */
    function setOwner(address _new_owner) public onlyOwner() {
        owner = _new_owner; 
    }
}

/**
*The Test Oracle contract for testing the push and callback functions
*/
contract Test_Oracle2 {

    /*Variables*/
    
    address private owner;
    bytes32 private queryID;
    string public usedAPI;
    string public API;
    string public API2;

    /*Structs*/
    struct QueryInfo {
        uint value;
        bool queried;
        uint date;
        uint calledTime;
        bool called;
    }  
    //Mapping of documents stored in the oracle
    mapping(uint => bytes32) public queryIds;
    mapping(bytes32 => QueryInfo ) public info;

    //Mapping of documents stored in the oracle
    mapping(uint => uint) internal oracle_values;
    mapping(uint => bool) public queried;

    /*Events*/
    event DocumentStored(uint _key, uint _value);
    event newOraclizeQuery(string description);
    event called(bool _wascalled);

    /*Modifiers*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    /**
    *@dev Constructor, sets two public api strings
    *e.g. "json(https://api.gdax.com/products/BTC-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT).price"
    * or "json(https://api.gdax.com/products/ETH-USD/ticker).price"
    * "json(https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT).price"
    */
     constructor(string _api, string _api2) public{
        owner = msg.sender;
        API = _api;
        API2 = _api2;
    }

    /**
    *@dev Allows the owner of the Oracle to store a document in the oracle_values mapping. Documents
    *represent underlying values at a specified date (key).
    */
    function StoreDocument(uint _key, uint _value) public onlyOwner() {
        if(_value == 0){
            _value = 1;
        }
        oracle_values[_key] = _value;
        emit DocumentStored(_key, _value);
        queried[_key] = true;
    }

    /**
    *@dev PushData - Sends an Oraclize query for entered API
    */
    function pushData(uint _key, uint _bal, uint _cost, bytes32 _queryID) public payable {
        uint _calledTime = now;
        QueryInfo storage currentQuery = info[queryIds[_key]];
        require(currentQuery.queried == false  && currentQuery.calledTime == 0 || 
            currentQuery.calledTime != 0  &&
            currentQuery.value == 0);

        if ( _cost > _bal) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH");
        } else {
            emit newOraclizeQuery("Oraclize queries sent");
            emit called(currentQuery.called); 
            if (currentQuery.called == false){
                usedAPI=API;
            //    currentQuery.called = true;
            } else if (currentQuery.called == true ){
                usedAPI=API2;   
            //    currentQuery.called = false;          
            }
            queryID = _queryID;
            queryIds[_key] = queryID;
            currentQuery = info[queryIds[_key]];
            currentQuery.queried = true;
            currentQuery.date = _key;
            currentQuery.calledTime = _calledTime;
            currentQuery.called = !currentQuery.called;
        }
    }
    

    /**
    *@dev Used to test callback
    *@param _oraclizeID unique oraclize identifier of call
    *@param _result Result of API call in string format
    */
     function callback(uint _result, bytes32 _oraclizeID) public {
        QueryInfo storage currentQuery = info[_oraclizeID];
        require(_oraclizeID == queryID);
        currentQuery.value = _result;
        currentQuery.called = false; 
        if(currentQuery.value == 0){
            currentQuery.value = 1;
        }
        emit DocumentStored(currentQuery.date, currentQuery.value);
    } 

    /*
    * gets API used for tests
    */
    function getusedAPI() public view returns(string){
        return usedAPI;
    }

    /**
    *@dev Determine if the Oracle was queried
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    *@return true or false based upon whether an API query has been 
    *initialized (or completed) for given date
    */
    function getQuery(uint _date) public view returns(bool){
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.queried;
    }

    /**
    *@dev RetrieveData - Returns stored value by given key
    *@param _date Daily unix timestamp of key storing value (GMT 00:00:00)
    *@return oracle_values for the date
    */
    function retrieveData(uint _date) public constant returns (uint) {
        QueryInfo storage currentQuery = info[queryIds[_date]];
        return currentQuery.value;
    }


    /**
    *@dev Set the new owner of the contract or test oracle?
    *@param _new_owner for the oracle? 
    */
    function setOwner(address _new_owner) public onlyOwner() {
        owner = _new_owner; 
    }
}

/**
*This contract is the specific DRCT base contract that holds the funds of the contract and
*redistributes them based upon the change in the underlying values
*/

contract TokenToTokenSwap {

    using TokenLibrary for TokenLibrary.SwapStorage;

    /*Variables*/
    TokenLibrary.SwapStorage public swap;


    /*Functions*/
    /**
    *@dev Constructor - Run by the factory at contract creation
    *@param _factory_address address of the factory that created this contract
    *@param _creator address of the person who created the contract
    *@param _userContract address of the _userContract that is authorized to interact with this contract
    *@param _start_date start date of the contract
    */
    constructor (address _factory_address, address _creator, address _userContract, uint _start_date) public {
        swap.startSwap(_factory_address,_creator,_userContract,_start_date);
    }
    
    /**
    *@dev Acts as a constructor when cloning the swap
    *@param _factory_address address of the factory that created this contract
    *@param _creator address of the person who created the contract
    *@param _userContract address of the _userContract that is authorized to interact with this contract
    *@param _start_date start date of the contract
    */
    function init (address _factory_address, address _creator, address _userContract, uint _start_date) public {
        swap.startSwap(_factory_address,_creator,_userContract,_start_date);
    }

    /**
    *@dev A getter function for retriving standardized variables from the factory contract
    *@return 
    *[userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens, , multiplier, duration, Start date, end_date
    */
    function showPrivateVars() public view returns (address[5],uint, uint, uint, uint, uint){
        return swap.showPrivateVars();
    }

    /**
    *@dev A getter function for retriving current swap state from the factory contract
    *@return current state (References swapState Enum: 1=created, 2=started, 3=ended)
    */
    function currentState() public view returns(uint){
        return swap.showCurrentState();
    }

    /**
    *@dev Allows the sender to create the terms for the swap
    *@param _amount Amount of Token that should be deposited for the notional
    *@param _senderAdd States the owner of this side of the contract (does not have to be msg.sender)
    */
    function createSwap(uint _amount, address _senderAdd) public {
        swap.createSwap(_amount,_senderAdd);
    }

    /**
    *@dev This function can be called after the swap is tokenized or after the Calculate function is called.
    *If the Calculate function has not yet been called, this function will call it.
    *The function then pays every token holder of both the long and short DRCT tokens
    *@param _topay number of contracts to try and pay (run it again if its not enough)
    *@return true if the oracle was called and all contracts were paid out or false once ?
    */
    function forcePay(uint _topay) public returns (bool) {
       swap.forcePay(_topay);
    }


}

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
    address internal owner;
    event StartContract(address _newswap, uint _amount);


    /*Functions*/
    constructor() public {
        owner = msg.sender;
    }

    /**
    *@dev Value must be sent with Initiate and enter the _amount(in wei) 
    *@param _startDate is the startDate of the contract you want to deploy
    *@param _amount is the amount of Ether on each side of the contract initially
    */
    function Initiate(uint _startDate, uint _amount) payable public{
        uint _fee = factory.fee();
        require(msg.value == _amount.mul(2) + _fee);
        address _swapadd = factory.deployContract.value(_fee)(_startDate,msg.sender);
        swap = TokenToTokenSwap_Interface(_swapadd);
        address token_address = factory.token();
        baseToken = Wrapped_Ether(token_address);
        baseToken.createToken.value(_amount.mul(2))();
        baseToken.transfer(_swapadd,_amount.mul(2));
        swap.createSwap(_amount, msg.sender);
        emit StartContract(_swapadd,_amount);
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
}

/**
*This is the basic wrapped Ether contract. 
*All money deposited is transformed into ERC20 tokens at the rate of 1 wei = 1 token
*/
contract Wrapped_Ether {

    using SafeMath for uint256;

    /*Variables*/

    //ERC20 fields
    string public name = "Wrapped Ether";
    uint public total_supply;
    mapping(address => uint) internal balances;
    mapping(address => mapping (address => uint)) internal allowed;

    /*Events*/
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event StateChanged(bool _success, string _message);

    /*Functions*/
    /**
    *@dev This function creates tokens equal in value to the amount sent to the contract
    */
    function createToken() public payable {
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        total_supply = total_supply.add(msg.value);
    }

    /**
    *@dev This function 'unwraps' an _amount of Ether in the sender's balance by transferring 
    *Ether to them
    *@param _value The amount of the token to unwrap
    */
    function withdraw(uint _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        total_supply = total_supply.sub(_value);
        msg.sender.transfer(_value);
    }

    /**
    *@param _owner is the owner address used to look up the balance
    *@return Returns the balance associated with the passed in _owner
    */
    function balanceOf(address _owner) public constant returns (uint bal) { 
        return balances[_owner]; 
    }

    /**
    *@dev Allows for a transfer of tokens to _to
    *@param _to The address to send tokens to
    *@param _amount The amount of tokens to send
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = balances[msg.sender] - _amount;
            balances[_to] = balances[_to] + _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *@dev Allows an address with sufficient spending allowance to send tokens on the behalf of _from
    *@param _from The address to send tokens from
    *@param _to The address to send tokens to
    *@param _amount The amount of tokens to send
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[_from] = balances[_from] - _amount;
            allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
            balances[_to] = balances[_to] + _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *@dev This function approves a _spender an _amount of tokens to use
    *@param _spender address
    *@param _amount amount the spender is being approved for
    *@return true if spender appproved successfully
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *@param _owner address
    *@param _spender address
    *@return Returns the remaining allowance of tokens granted to the _spender from the _owner
    */
    function allowance(address _owner, address _spender) public view returns (uint) {
       return allowed[_owner][_spender]; }

    /**
    *@dev Getter for the total_supply of wrapped ether
    *@return total supply
    */
    function totalSupply() public constant returns (uint) {
       return total_supply;
    }
}

/**
*The DRCTLibrary contains the reference code used in the DRCT_Token (an ERC20 compliant token
*representing the payout of the swap contract specified in the Factory contract).
*/
library DRCTLibrary{

    using SafeMath for uint256;

    /*Structs*/
    /**
    *@dev Keeps track of balance amounts in the balances array
    */
    struct Balance {
        address owner;
        uint amount;
        }

    struct TokenStorage{
        //This is the factory contract that the token is standardized at
        address factory_contract;
        //Total supply of outstanding tokens in the contract
        uint total_supply;
        //Mapping from: swap address -> user balance struct (index for a particular user's balance can be found in swap_balances_index)
        mapping(address => Balance[]) swap_balances;
        //Mapping from: swap address -> user -> swap_balances index
        mapping(address => mapping(address => uint)) swap_balances_index;
        //Mapping from: user -> dynamic array of swap addresses (index for a particular swap can be found in user_swaps_index)
        mapping(address => address[]) user_swaps;
        //Mapping from: user -> swap address -> user_swaps index
        mapping(address => mapping(address => uint)) user_swaps_index;
        //Mapping from: user -> total balance accross all entered swaps
        mapping(address => uint) user_total_balances;
        //Mapping from: owner -> spender -> amount allowed
        mapping(address => mapping(address => uint)) allowed;
    }   

    /*Events*/
    /**
    *@dev events for transfer and approvals
    */
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event CreateToken(address _from, uint _value);
    
    /*Functions*/
    /**
    *@dev Constructor - sets values for token name and token supply, as well as the 
    *factory_contract, the swap.
    *@param _factory 
    */
    function startToken(TokenStorage storage self,address _factory) public {
        self.factory_contract = _factory;
    }

    /**
    *@dev ensures the member is whitelisted
    *@param _member is the member address that is chekced agaist the whitelist
    */
    function isWhitelisted(TokenStorage storage self,address _member) internal view returns(bool){
        Factory_Interface _factory = Factory_Interface(self.factory_contract);
        return _factory.isWhitelisted(_member);
    }

    /**
    *@dev gets the factory address
    */
    function getFactoryAddress(TokenStorage storage self) external view returns(address){
        return self.factory_contract;
    }

    /**
    *@dev Token Creator - This function is called by the factory contract and creates new tokens
    *for the user
    *@param _supply amount of DRCT tokens created by the factory contract for this swap
    *@param _owner address
    *@param _swap address
    */
    function createToken(TokenStorage storage self,uint _supply, address _owner, address _swap) public{
        require(msg.sender == self.factory_contract);
        //Update total supply of DRCT Tokens
        self.total_supply = self.total_supply.add(_supply);
        //Update the total balance of the owner
        self.user_total_balances[_owner] = self.user_total_balances[_owner].add(_supply);
        //If the user has not entered any swaps already, push a zeroed address to their user_swaps mapping to prevent default value conflicts in user_swaps_index
        if (self.user_swaps[_owner].length == 0)
            self.user_swaps[_owner].push(address(0x0));
        //Add a new swap index for the owner
        self.user_swaps_index[_owner][_swap] = self.user_swaps[_owner].length;
        //Push a new swap address to the owner's swaps
        self.user_swaps[_owner].push(_swap);
        //Push a zeroed Balance struct to the swap balances mapping to prevent default value conflicts in swap_balances_index
        self.swap_balances[_swap].push(Balance({
            owner: 0,
            amount: 0
        }));
        //Add a new owner balance index for the swap
        self.swap_balances_index[_swap][_owner] = 1;
        //Push the owner's balance to the swap
        self.swap_balances[_swap].push(Balance({
            owner: _owner,
            amount: _supply
        }));
        emit CreateToken(_owner,_supply);
    }

    /**
    *@dev Called by the factory contract, and pays out to a _party
    *@param _party being paid
    *@param _swap address
    */
    function pay(TokenStorage storage self,address _party, address _swap) public{
        require(msg.sender == self.factory_contract);
        uint party_balance_index = self.swap_balances_index[_swap][_party];
        require(party_balance_index > 0);
        uint party_swap_balance = self.swap_balances[_swap][party_balance_index].amount;
        //reduces the users totals balance by the amount in that swap
        self.user_total_balances[_party] = self.user_total_balances[_party].sub(party_swap_balance);
        //reduces the total supply by the amount of that users in that swap
        self.total_supply = self.total_supply.sub(party_swap_balance);
        //sets the partys balance to zero for that specific swaps party balances
        self.swap_balances[_swap][party_balance_index].amount = 0;
    }

    /**
    *@dev Returns the users total balance (sum of tokens in all swaps the user has tokens in)
    *@param _owner user address
    *@return user total balance
    */
    function balanceOf(TokenStorage storage self,address _owner) public constant returns (uint balance) {
       return self.user_total_balances[_owner]; 
     }

    /**
    *@dev Getter for the total_supply of tokens in the contract
    *@return total supply
    */
    function totalSupply(TokenStorage storage self) public constant returns (uint _total_supply) {
       return self.total_supply;
    }

    /**
    *@dev Removes the address from the swap balances for a swap, and moves the last address in the
    *swap into their place
    *@param _remove address of prevous owner
    *@param _swap address used to get last addrss of the swap to replace the removed address
    */
    function removeFromSwapBalances(TokenStorage storage self,address _remove, address _swap) internal {
        uint last_address_index = self.swap_balances[_swap].length.sub(1);
        address last_address = self.swap_balances[_swap][last_address_index].owner;
        //If the address we want to remove is the final address in the swap
        if (last_address != _remove) {
            uint remove_index = self.swap_balances_index[_swap][_remove];
            //Update the swap's balance index of the last address to that of the removed address index
            self.swap_balances_index[_swap][last_address] = remove_index;
            //Set the swap's Balance struct at the removed index to the Balance struct of the last address
            self.swap_balances[_swap][remove_index] = self.swap_balances[_swap][last_address_index];
        }
        //Remove the swap_balances index for this address
        delete self.swap_balances_index[_swap][_remove];
        //Finally, decrement the swap balances length
        self.swap_balances[_swap].length = self.swap_balances[_swap].length.sub(1);
    }

    /**
    *@dev This is the main function to update the mappings when a transfer happens
    *@param _from address to send funds from
    *@param _to address to send funds to
    *@param _amount amount of token to send
    */
    function transferHelper(TokenStorage storage self,address _from, address _to, uint _amount) internal {
        //Get memory copies of the swap arrays for the sender and reciever
        address[] memory from_swaps = self.user_swaps[_from];
        //Iterate over sender's swaps in reverse order until enough tokens have been transferred
        for (uint i = from_swaps.length.sub(1); i > 0; i--) {
            //Get the index of the sender's balance for the current swap
            uint from_swap_user_index = self.swap_balances_index[from_swaps[i]][_from];
            Balance memory from_user_bal = self.swap_balances[from_swaps[i]][from_swap_user_index];
            //If the current swap will be entirely depleted - we remove all references to it for the sender
            if (_amount >= from_user_bal.amount) {
                _amount -= from_user_bal.amount;
                //If this swap is to be removed, we know it is the (current) last swap in the user's user_swaps list, so we can simply decrement the length to remove it
                self.user_swaps[_from].length = self.user_swaps[_from].length.sub(1);
                //Remove the user swap index for this swap
                delete self.user_swaps_index[_from][from_swaps[i]];
                //If the _to address already holds tokens from this swap
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                    //Get the index of the _to balance in this swap
                    uint to_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                    assert(to_balance_index != 0);
                    //Add the _from tokens to _to
                    self.swap_balances[from_swaps[i]][to_balance_index].amount = self.swap_balances[from_swaps[i]][to_balance_index].amount.add(from_user_bal.amount);
                    //Remove the _from address from this swap's balance array
                    removeFromSwapBalances(self,_from, from_swaps[i]);
                } else {
                    //Prepare to add a new swap by assigning the swap an index for _to
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                //Add the new swap to _to
                self.user_swaps[_to].push(from_swaps[i]);
                //Give the reciever the sender's balance for this swap
                self.swap_balances[from_swaps[i]][from_swap_user_index].owner = _to;
                //Give the reciever the sender's swap balance index for this swap
                self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances_index[from_swaps[i]][_from];
                //Remove the swap balance index from the sending party
                delete self.swap_balances_index[from_swaps[i]][_from];
            }
            //If there is no more remaining to be removed, we break out of the loop
            if (_amount == 0)
                break;
            } else {
                //The amount in this swap is more than the amount we still need to transfer
                uint to_swap_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                //If the _to address already holds tokens from this swap
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                    //Because both addresses are in this swap, and neither will be removed, we simply update both swap balances
                    self.swap_balances[from_swaps[i]][to_swap_balance_index].amount = self.swap_balances[from_swaps[i]][to_swap_balance_index].amount.add(_amount);
                } else {
                    //Prepare to add a new swap by assigning the swap an index for _to
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                    self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                    //And push the new swap
                    self.user_swaps[_to].push(from_swaps[i]);
                    //_to is not in this swap, so we give this swap a new balance index for _to
                    self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances[from_swaps[i]].length;
                    //And push a new balance for _to
                    self.swap_balances[from_swaps[i]].push(Balance({
                        owner: _to,
                        amount: _amount
                    }));
                }
                //Finally, update the _from user's swap balance
                self.swap_balances[from_swaps[i]][from_swap_user_index].amount = self.swap_balances[from_swaps[i]][from_swap_user_index].amount.sub(_amount);
                //Because we have transferred the last of the amount to the reciever, we break;
                break;
            }
        }
    }

    /**
    *@dev ERC20 compliant transfer function
    *@param _to Address to send funds to
    *@param _amount Amount of token to send
    *@return true for successful
    */
    function transfer(TokenStorage storage self, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[msg.sender];
        if (
            _to == msg.sender ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount
        ) return false;
        transferHelper(self,msg.sender, _to, _amount);
        self.user_total_balances[msg.sender] = self.user_total_balances[msg.sender].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    /**
    *@dev ERC20 compliant transferFrom function
    *@param _from address to send funds from (must be allowed, see approve function)
    *@param _to address to send funds to
    *@param _amount amount of token to send
    *@return true for successful
    */
    function transferFrom(TokenStorage storage self, address _from, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[_from];
        uint sender_allowed = self.allowed[_from][msg.sender];
        if (
            _to == _from ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount ||
            sender_allowed < _amount
        ) return false;
        transferHelper(self,_from, _to, _amount);
        self.user_total_balances[_from] = self.user_total_balances[_from].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        self.allowed[_from][msg.sender] = self.allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    *@dev ERC20 compliant approve function
    *@param _spender party that msg.sender approves for transferring funds
    *@param _amount amount of token to approve for sending
    *@return true for successful
    */
    function approve(TokenStorage storage self, address _spender, uint _amount) public returns (bool) {
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *@dev Counts addresses involved in the swap based on the length of balances array for _swap
    *@param _swap address
    *@return the length of the balances array for the swap
    */
    function addressCount(TokenStorage storage self, address _swap) public constant returns (uint) { 
        return self.swap_balances[_swap].length; 
    }

    /**
    *@dev Gets the owner address and amount by specifying the swap address and index
    *@param _ind specified index in the swap
    *@param _swap specified swap address
    *@return the owner address associated with a particular index in a particular swap
    *@return the amount to transfer associated with a particular index in a particular swap
    */
    function getBalanceAndHolderByIndex(TokenStorage storage self, uint _ind, address _swap) public constant returns (uint, address) {
        return (self.swap_balances[_swap][_ind].amount, self.swap_balances[_swap][_ind].owner);
    }

    /**
    *@dev Gets the index by specifying the swap and owner addresses
    *@param _owner specifed address
    *@param _swap  specified swap address
    *@return the index associated with the _owner address in a particular swap
    */
    function getIndexByAddress(TokenStorage storage self, address _owner, address _swap) public constant returns (uint) {
        return self.swap_balances_index[_swap][_owner]; 
    }

    /**
    *@dev Look up how much the spender or contract is allowed to spend?
    *@param _owner 
    *@param _spender party approved for transfering funds 
    *@return the allowed amount _spender can spend of _owner's balance
    */
    function allowance(TokenStorage storage self, address _owner, address _spender) public constant returns (uint) {
        return self.allowed[_owner][_spender]; 
    }
}

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


/**
*The TokenLibrary contains the reference code used to create the specific DRCT base contract 
*that holds the funds of the contract and redistributes them based upon the change in the
*underlying values
*/

library TokenLibrary{

    using SafeMath for uint256;

    /*Variables*/
    enum SwapState {
        created,
        started,
        ended
    }
    
    /*Structs*/
    struct SwapStorage{
        //The Oracle address (check for list at www.github.com/DecentralizedDerivatives/Oracles)
        address oracle_address;
        //Address of the Factory that created this contract
        address factory_address;
        Factory_Interface factory;
        address creator;
        //Addresses of ERC20 token
        address token_address;
        ERC20_Interface token;
        //Enum state of the swap
        SwapState current_state;
        //Start date, end_date, multiplier duration,start_value,end_value,fee
        uint[8] contract_details;
        // pay_to_x refers to the amount of the base token (a or b) to pay to the long or short side based upon the share_long and share_short
        uint pay_to_long;
        uint pay_to_short;
        //Address of created long and short DRCT tokens
        address long_token_address;
        address short_token_address;
        //Number of DRCT Tokens distributed to both parties
        uint num_DRCT_tokens;
        //The notional that the payment is calculated on from the change in the reference rate
        uint token_amount;
        address userContract;
    }

    /*Events*/
    event SwapCreation(address _token_address, uint _start_date, uint _end_date, uint _token_amount);
    //Emitted when the swap has been paid out
    event PaidOut(uint pay_to_long, uint pay_to_short);

    /*Functions*/
    /**
    *@dev Acts the constructor function in the cloned swap
    *@param _factory_address
    *@param _creator address of swap creator
    *@param _userContract address
    *@param _start_date swap start date
    */
    function startSwap (SwapStorage storage self, address _factory_address, address _creator, address _userContract, uint _start_date) internal {
        require(self.creator == address(0));
        self.creator = _creator;
        self.factory_address = _factory_address;
        self.userContract = _userContract;
        self.contract_details[0] = _start_date;
        self.current_state = SwapState.created;
        self.contract_details[7] = 0;
    }

    /**
    *@dev A getter function for retriving standardized variables from the factory contract
    *@return 
    *[userContract, Long Token addresss, short token address, oracle address, base token address], number DRCT tokens, , multiplier, duration, Start date, end_date
    */
    function showPrivateVars(SwapStorage storage self) internal view returns (address[5],uint, uint, uint, uint, uint){
        return ([self.userContract, self.long_token_address,self.short_token_address, self.oracle_address, self.token_address], self.num_DRCT_tokens, self.contract_details[2], self.contract_details[3], self.contract_details[0], self.contract_details[1]);
    }

    /**
    *@dev Allows the sender to create the terms for the swap
    *@param _amount Amount of Token that should be deposited for the notional
    *@param _senderAdd States the owner of this side of the contract (does not have to be msg.sender)
    */
    function createSwap(SwapStorage storage self,uint _amount, address _senderAdd) internal{
       require(self.current_state == SwapState.created && msg.sender == self.creator  && _amount > 0 || (msg.sender == self.userContract && _senderAdd == self.creator) && _amount > 0);
        self.factory = Factory_Interface(self.factory_address);
        getVariables(self);
        self.contract_details[1] = self.contract_details[0].add(self.contract_details[3].mul(86400));
        assert(self.contract_details[1]-self.contract_details[0] < 28*86400);
        self.token_amount = _amount;
        self.token = ERC20_Interface(self.token_address);
        assert(self.token.balanceOf(address(this)) == SafeMath.mul(_amount,2));
        uint tokenratio = 1;
        (self.long_token_address,self.short_token_address,tokenratio) = self.factory.createToken(self.token_amount,self.creator,self.contract_details[0]);
        self.num_DRCT_tokens = self.token_amount.div(tokenratio);
        emit SwapCreation(self.token_address,self.contract_details[0],self.contract_details[1],self.token_amount);
        self.current_state = SwapState.started;
    }

    /**
    *@dev Getter function for contract details saved in the SwapStorage struct
    *Gets the oracle address, duration, multiplier, base token address, and fee
    *and from the Factory.getVariables function.
    */
    function getVariables(SwapStorage storage self) internal{
        (self.oracle_address,self.contract_details[3],self.contract_details[2],self.token_address,self.contract_details[6]) = self.factory.getVariables();
    }

    /**
    *@dev check if the oracle has been queried within the last day 
    *@return true if it was queried and the start and end values are not zero
    *and false if they are.
    */
    function oracleQuery(SwapStorage storage self) internal returns(bool){
        Oracle_Interface oracle = Oracle_Interface(self.oracle_address);
        uint _today = now - (now % 86400);
        uint i = 0;
        if(_today >= self.contract_details[0]){
            while(i <= (_today- self.contract_details[0])/86400 && self.contract_details[4] == 0){
                if(oracle.getQuery(self.contract_details[0]+i*86400)){
                    self.contract_details[4] = oracle.retrieveData(self.contract_details[0]+i*86400);
                }
                i++;
            }
        }
        i = 0;
        if(_today >= self.contract_details[1]){
            while(i <= (_today- self.contract_details[1])/86400 && self.contract_details[5] == 0){
                if(oracle.getQuery(self.contract_details[1]+i*86400)){
                    self.contract_details[5] = oracle.retrieveData(self.contract_details[1]+i*86400);
                }
                i++;
            }
        }
        if(self.contract_details[4] != 0 && self.contract_details[5] != 0){
            return true;
        }
        else{
            return false;
        }
    }

    /**
    *@dev This function calculates the payout of the swap. It can be called after the Swap has been tokenized.
    *The value of the underlying cannot reach zero, but rather can only get within 0.001 * the precision
    *of the Oracle.
    */
    function Calculate(SwapStorage storage self) internal{
        uint ratio;
        self.token_amount = self.token_amount.mul(10000-self.contract_details[6]).div(10000);
        if (self.contract_details[4] > 0 && self.contract_details[5] > 0)
            ratio = (self.contract_details[5]).mul(100000).div(self.contract_details[4]);
            if (ratio > 100000){
                ratio = (self.contract_details[2].mul(ratio - 100000)).add(100000);
            }
            else if (ratio < 100000){
                    ratio = SafeMath.min(100000,(self.contract_details[2].mul(100000-ratio)));
                    ratio = 100000 - ratio;
            }
        else if (self.contract_details[5] > 0)
            ratio = 10e10;
        else if (self.contract_details[4] > 0)
            ratio = 0;
        else
            ratio = 100000;
        ratio = SafeMath.min(200000,ratio);
        self.pay_to_long = (ratio.mul(self.token_amount)).div(self.num_DRCT_tokens).div(100000);
        self.pay_to_short = (SafeMath.sub(200000,ratio).mul(self.token_amount)).div(self.num_DRCT_tokens).div(100000);
    }

    /**
    *@dev This function can be called after the swap is tokenized or after the Calculate function is called.
    *If the Calculate function has not yet been called, this function will call it.
    *The function then pays every token holder of both the long and short DRCT tokens
    *@param _numtopay number of contracts to try and pay (run it again if its not enough)
    *@return true if the oracle was called and all contracts are paid or false ?
    */
    function forcePay(SwapStorage storage self,uint _numtopay) internal returns (bool) {
       //Calls the Calculate function first to calculate short and long shares
        require(self.current_state == SwapState.started && now >= self.contract_details[1]);
        bool ready = oracleQuery(self);
        if(ready){
            Calculate(self);
            //Loop through the owners of long and short DRCT tokens and pay them
            DRCT_Token_Interface drct = DRCT_Token_Interface(self.long_token_address);
            uint[6] memory counts;
            address token_owner;
            counts[0] = drct.addressCount(address(this));
            counts[1] = counts[0] <= self.contract_details[7].add(_numtopay) ? counts[0] : self.contract_details[7].add(_numtopay).add(1);
            //Indexing begins at 1 for DRCT_Token balances
            if(self.contract_details[7] < counts[1]){
                for(uint i = counts[1]-1; i > self.contract_details[7] ; i--) {
                    (counts[4], token_owner) = drct.getBalanceAndHolderByIndex(i, address(this));
                    paySwap(self,token_owner,counts[4], true);
                }
            }

            drct = DRCT_Token_Interface(self.short_token_address);
            counts[2] = drct.addressCount(address(this));
            counts[3] = counts[2] <= self.contract_details[7].add(_numtopay) ? counts[2] : self.contract_details[7].add(_numtopay).add(1);
            if(self.contract_details[7] < counts[3]){
                for(uint j = counts[3]-1; j > self.contract_details[7] ; j--) {
                    (counts[5], token_owner) = drct.getBalanceAndHolderByIndex(j, address(this));
                    paySwap(self,token_owner,counts[5], false);
                }
            }
            if (counts[0] == counts[1] && counts[2] == counts[3]){
                self.token.transfer(self.factory_address, self.token.balanceOf(address(this)));
                emit PaidOut(self.pay_to_long,self.pay_to_short);
                self.current_state = SwapState.ended;
            }
            self.contract_details[7] = self.contract_details[7].add(_numtopay);
        }
        return ready;
    }

    /**
    *This function pays the receiver an amount determined by the Calculate function
    *@param _receiver is the recipient of the payout
    *@param _amount is the amount of token the recipient holds
    *@param _is_long is true if the reciever holds a long token
    */
    function paySwap(SwapStorage storage self,address _receiver, uint _amount, bool _is_long) internal {
        if (_is_long) {
            if (self.pay_to_long > 0){
                self.token.transfer(_receiver, _amount.mul(self.pay_to_long));
                self.factory.payToken(_receiver,self.long_token_address);
            }
        } else {
            if (self.pay_to_short > 0){
                self.token.transfer(_receiver, _amount.mul(self.pay_to_short));
                self.factory.payToken(_receiver,self.short_token_address);
            }
        }
    }

    /**
    *@dev Getter function for swap state
    *@return current state of swap
    */
    function showCurrentState(SwapStorage storage self)  internal view returns(uint) {
        return uint(self.current_state);
    }
    
}

//Swap Deployer functions - descriptions can be found in Deployer.sol
interface Deployer_Interface {
  function newContract(address _party, address user_contract, uint _start_date) external payable returns (address);
}

//DRCT_Token functions - descriptions can be found in DRCT_Token.sol
interface DRCT_Token_Interface {
  function addressCount(address _swap) external constant returns (uint);
  function getBalanceAndHolderByIndex(uint _ind, address _swap) external constant returns (uint, address);
  function getIndexByAddress(address _owner, address _swap) external constant returns (uint);
  function createToken(uint _supply, address _owner, address _swap) external;
  function getFactoryAddress() external view returns(address);
  function pay(address _party, address _swap) external;
  function partyCount(address _swap) external constant returns(uint);
}

//ERC20 function interface
interface ERC20_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
}

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) external returns (address,address, uint);
  function payToken(address _party, address _token_add) external;
  function deployContract(uint _start_date) external payable returns (address);
   function getBase() external view returns(address);
  function getVariables() external view returns (address, uint, uint, address,uint);
  function isWhitelisted(address _member) external view returns (bool);
}

interface Membership_Interface {
    function getMembershipType(address _member) external constant returns(uint);
}

//Swap Oracle functions - descriptions can be found in Oracle.sol
interface Oracle_Interface{
  function getQuery(uint _date) external view returns(bool);
  function retrieveData(uint _date) external view returns (uint);
  function pushData() external payable;
}

//Swap interface- descriptions can be found in TokenToTokenSwap.sol
interface TokenToTokenSwap_Interface {
  function createSwap(uint _amount, address _senderAdd) external;
}

//ERC20 function interface with create token and withdraw
interface Wrapped_Ether_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
  function withdraw(uint _value) external;
  function createToken() external;

}
