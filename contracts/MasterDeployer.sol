pragma solidity ^0.4.23;

import "./libraries/SafeMath.sol";
import './Factory.sol';
import "./CloneFactory.sol";

/*This contract deploys a factory contract*/

contract MasterDeployer is CloneFactory{
    /*Variables*/
    using SafeMath for uint256;
	address[] factory_contracts;
	address private factory;
	mapping(address => uint) public factory_index;

    /*Events*/
	event NewFactory(address _factory);

    /*Functions*/
	constructor() public {
		factory_contracts.push(address(0));
	}
	
	function setFactory(address _factory) public onlyOwner(){
		factory = _factory;
	}

	function deployFactory() public onlyOwner() returns(address){
		address _new_fac = createClone(factory);
		factory_index[_new_fac] = factory_contracts.length;
		factory_contracts.push(_new_fac);
		Factory(_new_fac).init(msg.sender);
		emit NewFactory(_new_fac);
	}

	function removeFactory(address _factory) public onlyOwner(){
		uint256 fIndex = factory_index[_factory];
        uint256 lastFactoryIndex = factory_contracts.length.sub(1);
        address lastFactory = factory_contracts[lastFactoryIndex];
        factory_contracts[fIndex] = lastFactory;
        factory_index[lastFactory] = fIndex;
        factory_contracts.length--;
        factory_index[_factory] = 0;
	}

	function getFactoryCount() public constant returns(uint){
		return factory_contracts.length - 1;
	}

	function getFactorybyIndex(uint _index) public constant returns(address){
		return factory_contracts[_index];
	}
}