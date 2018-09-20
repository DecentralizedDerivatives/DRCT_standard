pragma solidity ^0.4.24;

interface Exchange_Interface { 
    function setOrderNonce(uint _order_nonce) external ;
    function getOrderNonce() external view returns(uint);
    function setOpenDdaListAssets(address _ddaListAsset) external ;
    function getopenDdaListAssets() external view  returns (address[]);
    function setopenDdaListIndex(address _ddaListAsset, uint _value) external ;
    function getopenDdaListIndex(address _ddaListAsset) external view  returns (uint);
    function setDdaListAssetInfoAll(address _assetAddress, uint _price, uint _amount, bool _isLong) external ;
    function setDdaListAssetInfoAmount(address _assetAddress, uint _amount) external  ;
    function getDdaListAssetInfo(address _assetAddress) external  view returns(uint, uint, bool);
    function setOpenBooks(address _openBookAdd) external  ;
    function getBookCount()  external  constant returns(uint) ;
    function setOrder(uint256 _orderId, address _maker, uint256 _price,uint256 _amount, address _tokenadd) external ;
    function getOrder(uint256 _orderId) external view returns(address,uint,uint,address);
    function setForSale(address _tokenadd, uint _order_nonce)  external  ;
    function getOrderCount(address _token)  external  constant returns(uint) ;
    function getForSaleOrderId(address _tokenadd)  external  view returns(uint256[]);
    function setForSaleIndex(uint _order_nonce, uint _order_count)  external  ;
    function getForSaleIndex(uint _order_nonce)  external  view returns(uint);
    function getOrders(address _token)  external  constant returns(uint[]) ;
    function setOpenBookIndex(address _order, uint _order_index)  external  ;
    function getOpenBookIndex(address _order)  external  view returns(uint);
    function setUserOrders(address _user, uint _order_nonce)  external  ;
    function getUserOrders(address _user)  external  constant returns(uint[]) ;
    function setUserOrderIndex(address _user, uint _order_nonce)  external ;
    function getUserOrderIndex(uint _order_nonce)  external  view returns(uint);
    function blacklistParty(address _address, bool _motion)  external  ;
    function isBlacklist(address _address)  external view returns(bool) ;
}
