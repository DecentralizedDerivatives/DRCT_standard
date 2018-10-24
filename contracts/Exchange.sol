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
    ExchangeStorage internal _storage;

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
        require(msg.sender == _storage.getOwner());
        _;
    }

    /*Functions*/
    /**
    *@dev the constructor argument to set the owner and initialize the array.
    */
    function init() public onlyOwner{
        _storage.setOwner(msg.sender);
        _storage.setOpenBooks(address(0));
        _storage.setOrderNonce(1);
    }




    function setOwner(address _owner) public onlyOwner{        
       _storage.setOwner(_owner);
    }


    /**
    *@dev list allows a party to place an order on the orderbookas
    *@param _tokenadd address of the drct tokens
    *@param _amount number of DRCT tokens
    *@param _price uint256 price of all tokens in wei
    */
    function list(address _tokenadd, uint256 _amount, uint256 _price) external {
        require (_storage.isBlacklist(msg.sender) == false  && _price > 0); 
        ERC20_Interface token = ERC20_Interface(_tokenadd);
        require(_storage.getTotalListed(msg.sender,_tokenadd) + _amount <= token.allowance(msg.sender,address(this)));
        uint fsIndex = _storage.getOrderCount(_tokenadd);
        if(fsIndex == 0 ){
            _storage.setForSale(_tokenadd,0);
            fsIndex += 1;
        }
        uint _order_nonce = _storage.getOrderNonce();  
        _storage.setForSaleIndex(_order_nonce,fsIndex);
        _storage.setForSale(_tokenadd,_order_nonce);
        _storage.setOrder(_order_nonce, msg.sender, _price, _amount,_tokenadd);
        if(_storage.getOpenBookIndex(_tokenadd) == 0){   
            _storage.setOpenBookIndex(_tokenadd, _storage.getBookCount());
            _storage.setOpenBooks(_tokenadd);
        }
        _storage.setUserOrderIndex(msg.sender, _order_nonce);
        _storage.setUserOrders(msg.sender, _order_nonce);
        _storage.setOrderNonce(_order_nonce + 1);
        _storage.setTotalListed(_tokenadd,msg.sender,_amount);
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
        require (_storage.isBlacklist(msg.sender)==false);
        _storage.setDdaListAssetInfoAll( _asset, _price,  _amount, _isLong);
        _storage.setOpenDdaListIndex(_asset, _storage.getCountopenDdaListAssets());
        _storage.setOpenDdaListAssets(_asset);      
    }  

    /**
    *@notice This allows the owner to stop a malicious party from spamming the orderbook
    *@dev Allows the owner to blacklist addresses from using this exchange
    *@param _address the address of the party to blacklist
    *@param _motion true or false depending on if blacklisting or not
    */
    function blacklistParty(address _address, bool _motion) public onlyOwner {
        _storage.blacklistParty(_address,_motion);
    }
    /**
    *@dev list allows a DDA to remove asset 
    *@param _asset address 
    */
    function unlistDda(address _asset) public onlyOwner() {
        require (_storage.isBlacklist(msg.sender)==false);
        uint256 indexToDelete;
        uint256 lastAcctIndex;
        address lastAdd;
        _storage.setDdaListAssetInfoAll(_asset, 0, 0, false); 
        indexToDelete = _storage.getOpenDdaListIndex(_asset);
        lastAcctIndex = _storage.getCountopenDdaListAssets().sub(1);
        lastAdd = _storage.getOpenDdaListAddbyIndex(lastAcctIndex);
        _storage.setOpenDdaListAssetByIndex(indexToDelete, lastAdd);
        _storage.setOpenDdaListIndex(lastAdd, indexToDelete);
        _storage.setOpenDdaArrayLength(); 
        _storage.setOpenDdaListIndex(_asset, 0);
    } 

    /**
    *@dev buy allows a party to partially fill an order
    *@param _asset is the address of the assset listed
    *@param _amount is the amount of tokens to buy
    */
    function buyPerUnit(address _asset, uint256 _amount) external payable {
        require (_storage.isBlacklist(msg.sender)==false);
        uint listing_amount = _storage.getDdaListAssetInfoAmount(_asset);
        require(_amount <= listing_amount);
        uint totalPrice = _amount.mul(listing_amount);
        require(msg.value == totalPrice);
        address owner = _storage.getOwner();
        ERC20_Interface token = ERC20_Interface(_asset);
        if(token.allowance(owner,address(this)) >= _amount){
            assert(token.transferFrom(owner,msg.sender, _amount));
            owner.transfer(totalPrice);
            _storage.setDdaListAssetInfoAmount(_asset,listing_amount.sub(_amount));
        }
    } 

    /**
    *@dev unlist allows a party to remove their order from the orderbook
    *@param _orderId is the uint256 ID of order
    */
     function unlist(uint256 _orderId) external {
        require(_storage.getForSaleIndex(_orderId) > 0);
        require(msg.sender == _storage.getOrderMaker(_orderId)  || msg.sender == _storage.getOwner());
        address _order_asset = _storage.getOrderAsset(_orderId);
        uint _order_price = _storage.getOrderPrice(_orderId);
        uint _order_amount = _storage.getOrderAmount(_orderId);
        _storage.unLister(_orderId);
        emit OrderRemoved(msg.sender, _order_asset,_order_amount,_order_price);
    } 

    /**
    *@dev buy allows a party to fill an order
    *@param _orderId is the uint256 ID of order
    */
    function buy(uint256 _orderId) external payable {
        address _order_maker = _storage.getOrderMaker(_orderId);
        address _order_asset = _storage.getOrderAsset(_orderId);
        uint _order_price = _storage.getOrderPrice(_orderId);
        uint _order_amount = _storage.getOrderAmount(_orderId);
        require(_order_price != 0 && _order_maker != address(0) && _order_asset != address(0) && _order_amount!= 0);
        require(msg.value == _order_price);
        require(_storage.isBlacklist(msg.sender) == false);
        ERC20_Interface token = ERC20_Interface(_order_asset);
        assert(token.transferFrom(_order_maker,msg.sender, _order_amount));
        _order_maker.transfer(_order_price);
        _storage.unLister(_orderId);
        emit Sale(msg.sender,_order_asset,_order_amount,_order_price);
    }  

    /**
    *Getter Functions
    */
    function isBlacklist(address _address) public view returns(bool) {
        return _storage.isBlacklist(_address);
    }
    function getOrder(uint256 _orderId) public view returns(address,uint ,uint,address){
        return _storage.getOrder(_orderId);
    } 
    function getOrderMaker(uint256 _orderId) public view returns(address)  {
        return _storage.getOrderMaker(_orderId);
    }
    function getOrderPrice(uint256 _orderId) public view returns(uint)  {
        return _storage.getOrderPrice(_orderId);
    } 
    function getOrderAmount(uint256 _orderId) public view returns(uint){
        return _storage.getOrderAmount(_orderId);
    }
    function getOrderAsset(uint256 _orderId) public view returns(address){
        return _storage.getOrderAsset(_orderId);
    }
    function getOwner() external view returns(address){
        return _storage.getOwner();
    }
    function getOrderCount(address _token) public constant returns(uint) {
        return _storage.getOrderCount(_token);
    } 
    function getBookCount() public constant returns(uint) {
        return _storage.getBookCount();
    }
    function getOrders(address _token) public constant returns(uint[]) {
        return _storage.getOrders(_token);
    } 
    function getUserOrders(address _user) public constant returns(uint[]) {
        return _storage.getUserOrders(_user);
    } 
    function getOpenDdaListAssets() view public returns (address[]){
        return _storage.getOpenDdaListAssets();
    } 
    function getOpenDdaListAddbyIndex(uint _index) view public returns (address){
        return _storage.getOpenDdaListAddbyIndex(_index);
    }
    function getDdaListAssetInfo(address _assetAddress) public view returns(uint, uint, bool){
        return _storage.getDdaListAssetInfo(_assetAddress);
    } 
    function getDdaListAssetInfoAmount(address _assetAddress) public view returns(uint) {
        return _storage.getDdaListAssetInfoAmount(_assetAddress);
    }
    function getDdaListAssetInfoPrice(address _assetAddress) public view returns(uint) {
        return _storage.getDdaListAssetInfoPrice(_assetAddress);
    }
    function getTotalListed(address _owner, address _tokenadd) public view returns (uint) {
        return _storage.getTotalListed(_owner,_tokenadd);
    }
    function getOrderNonce() public view returns(uint) {
        return _storage.getOrderNonce();
    }
    function getCountopenDdaListAssets() view public returns (uint) {
        return _storage.getCountopenDdaListAssets();
    }
    function getOpenDdaListIndex(address _ddaListAsset) view public returns (uint)  {
        return _storage.getOpenDdaListIndex(_ddaListAsset);
    }
    function getForSaleOrderId(address _tokenadd) public view returns(uint256[])  {
        return _storage.getForSaleOrderId(_tokenadd);
    }
    function getForSaleIndex(uint _order_nonce) public view returns(uint)  {
        return _storage.getForSaleIndex(_order_nonce);
    }
    function getOpenBookIndex(address _order) public view returns(uint) {
        return _storage.getOpenBookIndex(_order);
    }
    function getUserOrderIndex(uint _order_nonce) public view returns(uint) {
        return _storage.getUserOrderIndex(_order_nonce);
    }
}

