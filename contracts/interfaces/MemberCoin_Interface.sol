pragma solidity ^0.4.21;

interface MemberCoin_Interface {
    function getMemberType(address _member) external constant returns(uint);
}
