pragma solidity ^0.4.24;

interface Exchange_Interface { 
    function setOrderNonce(uint _order_nonce) public ;
    function getOrderNonce() external view returns(uint);
    function setOpenDdaListAssets(address _ddaListAsset) public;
    function getopenDdaListAssets() view public returns (address[]);
    function setopenDdaListIndex(address _ddaListAsset, uint _value) public ;
    function getopenDdaListIndex(address _ddaListAsset) view public returns (uint);
    function setDdaListAssetInfoAll(address _assetAddress, uint _price, uint _amount, bool _isLong) public;
    function setDdaListAssetInfoAmount(address _assetAddress, uint _amount) public ;
    function getDdaListAssetInfo(address _assetAddress) public view returns(uint, uint, bool);
    function setOpenBooks(address _openBookAdd) public ;
    function getBookCount() public constant returns(uint) ;
    function setOrder(uint256 _orderId, address _maker, uint256 _price,uint256 _amount, address _tokenadd) public ;
    function getOrder(uint256 _orderId) external view returns(address,uint,uint,address);
    function setForSale(address _tokenadd, uint _order_nonce) public ;
    function getOrderCount(address _token) public constant returns(uint) ;
    function getForSaleOrderId(address _tokenadd) public view returns(uint256[]);
    function setForSaleIndex(uint _order_nonce, uint _order_count) public ;
    function getForSaleIndex(uint _order_nonce) public view returns(uint);
    function getOrders(address _token) public constant returns(uint[]) ;
    function setOpenBookIndex(address _order, uint _order_index) public ;
    function getOpenBookIndex(address _order) public view returns(uint);
    function setUserOrders(address _user, uint _order_nonce) public ;
    function getUserOrders(address _user) public constant returns(uint[]) ;
    function setUserOrderIndex(address _user, uint _order_nonce) public ;
    function getUserOrderIndex(uint _order_nonce) public view returns(uint);
    function blacklistParty(address _address, bool _motion) public  ;
    function isBlacklist(address _address) public view returns(bool) ;
}
