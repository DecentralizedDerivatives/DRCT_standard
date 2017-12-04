pragma solidity ^0.4.17;

contract Tester {
    address oracleAddress;
    address baseToken1;
    address baseToken2;
    address factory_address;
    address drct1;
    address drct2;
    Factory factory;
    Oracle oracle;

    
    function InitialCreate() public returns(address){
        oracleAddress = new Oracle();
        baseToken1 = new Wrapped_Ether();
        baseToken2 = new Wrapped_Ether();
        factory_address = new Factory();
        drct1 = new DRCT_Token(factory_address);
        drct2 = new DRCT_Token(factory_address);
        return factory_address;
    }
    
    function setVars(uint _startval, uint _endval) public {
        factory = Factory(factory_address);
        oracle = Oracle(oracleAddress);
        factory.setStartDate(1543881600);
        factory.setVariables(1000000000000000,1000000000000000,7,2);
        factory.setBaseTokens(baseToken1,baseToken2);
        factory.setOracleAddress(oracleAddress);
        factory.settokens(drct1,drct2);
        oracle.StoreDocument(1543881600, _startval);
        oracle.StoreDocument(1544486400,_endval);
        oracle.setOwner(msg.sender);
         factory.setOwner(msg.sender);
    }
}


