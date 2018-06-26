pragma solidity ^0.4.23;

import "./libraries/SafeMath.sol";
import './Factory.sol';
import "./CloneFactory.sol";

/**This contract deploys a factory contract and uses CloneFactory to clone the factory
*specified.
*/

contract MasterDeployer is CloneFactory{
    
    using SafeMath for uint256;

    /*Variables*/
	address[] factory_contracts;
	address private factory;
	mapping(address => uint) public factory_index;

    /*Events*/
	event NewFactory(address _factory);

    /*Functions*/
    /**
    *@dev Initiates the factory_contract array with address(0)
    */
	constructor() public {
		factory_contracts.push(address(0));
	}

    /**
    *@dev Set factory address to clone
    *@param _factory address to clone
    */	
	function setFactory(address _factory) public onlyOwner(){
		factory = _factory;
	}

    /**
    *@dev creates a new factory by cloning the factory specified in setFactory.
    *@return _new_fac which is the new factory address
    */
	function deployFactory() public onlyOwner() returns(address){
		address _new_fac = createClone(factory);
		factory_index[_new_fac] = factory_contracts.length;
		factory_contracts.push(_new_fac);
		Factory(_new_fac).init(msg.sender);
		emit NewFactory(_new_fac);
		return _new_fac;
	}

    /**
    *@dev Removes the factory specified
    *@param _factory address to remove
    */
	function removeFactory(address _factory) public onlyOwner(){
		require(_factory != address(0) && factory_index[_factory] != 0);
		uint256 fIndex = factory_index[_factory];
        uint256 lastFactoryIndex = factory_contracts.length.sub(1);
        address lastFactory = factory_contracts[lastFactoryIndex];
        factory_contracts[fIndex] = lastFactory;
        factory_index[lastFactory] = fIndex;
        factory_contracts.length--;
        factory_index[_factory] = 0;
	}

    /**
    *@dev Counts the number of factories
    *@returns the number of active factories
    */
	function getFactoryCount() public constant returns(uint){
		return factory_contracts.length - 1;
	}

    /**
    *@dev Returns the factory address for the specified index
    *@param _index for factory to look up in the factory_contracts array
    *@return factory address for the index specified
    */
	function getFactorybyIndex(uint _index) public constant returns(address){
		return factory_contracts[_index];
	}
}
