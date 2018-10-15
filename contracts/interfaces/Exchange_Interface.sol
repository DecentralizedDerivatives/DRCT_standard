pragma solidity ^0.4.24;

interface Exchange_Interface { 
    function setOrderNonce(uint _order_nonce) external ;
    function setOpenDdaListAssets(address _ddaListAsset) external ;
    function setAllowedLeftToList(address _spender, uint _amount) external ;
    function setOpenDdaListAssetByIndex(uint _indexToDelete, address _lastAdd) external;
    function setopenDdaListIndex(address _ddaListAsset, uint _value) external ;
    function setOpenDdaArrayLength() external ;
    function setDdaListAssetInfoAll(address _assetAddress, uint _price, uint _amount, bool _isLong) external ;
    function setDdaListAssetInfoAmount(address _assetAddress, uint _amount) external  ;
    function setOpenBooks(address _openBookAdd) external  ;
    function setOrder(uint256 _orderId, address _maker, uint256 _price,uint256 _amount, address _tokenadd) external ;
    function setForSale(address _tokenadd, uint _order_nonce)  external  ;
    function setForSaleIndex(uint _order_nonce, uint _order_count)  external  ;
    function setOpenBookIndex(address _order, uint _order_index)  external  ;
    function setUserOrders(address _user, uint _order_nonce)  external  ;
    function setUserOrderIndex(address _user, uint _order_nonce)  external ;
    function blacklistParty(address _address, bool _motion)  external  ;
    function unLister(uint256 _orderId, uint _order) external;
}
