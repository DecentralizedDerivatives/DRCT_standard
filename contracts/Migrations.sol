pragma solidity ^0.4.21;

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
    function Migrations() public {
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
    @dev ?
    @param new_address ?
    */
    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}
