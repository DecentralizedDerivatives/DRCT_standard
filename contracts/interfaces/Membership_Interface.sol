pragma solidity ^0.4.24;

interface Membership_Interface {
    function getMembershipType(address _member) external constant returns(uint);
}
