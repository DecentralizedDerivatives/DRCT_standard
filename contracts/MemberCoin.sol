pragma solidity ^0.4.21;

import "./libraries/SafeMath.sol";


/**
*This is the basic wrapped Ether contract. 
*All money deposited is transformed into ERC20 tokens at the rate of 1 wei = 1 token
*/
contract MemberCoin{

    using SafeMath for uint256;

    mapping(address => uint) members;

    function setMember(address _member, uint _type)  public{
        members[_member] = _type;
    }

    function getMemberType(address _member) public constant returns(uint){
        return members[_member];
    }
}
