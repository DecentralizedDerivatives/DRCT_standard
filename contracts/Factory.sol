pragma solidity ^0.4.21;

import "./interfaces/Deployer_Interface.sol";
import "./DRCT_Token.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/Wrapped_Ether_Interface.sol";
import "./interfaces/MemberCoin_Interface.sol";


/**
*The Factory contract sets the standardized variables and also deploys new contracts based on
*these variables for the user.  
*/
contract Factory {
    using SafeMath for uint256;
    /*Variables*/
    //Addresses of the Factory owner and oracle. For oracle information, 
    //check www.github.com/DecentralizedDerivatives/Oracles
    address public owner;
    address public oracle_address;
    //Address of the user contract
    address public user_contract;
    //Address of the deployer contract
    address internal deployer_address;
    Deployer_Interface internal deployer;
    address public token;
    //A fee for creating a swap in wei.  Plan is for this to be zero, however can be raised to prevent spam
    uint public fee;
    //Duration of swap contract in days
    uint public duration;
    //Multiplier of reference rate.  2x refers to a 50% move generating a 100% move in the contract payout values
    uint public multiplier;
    //Token_ratio refers to the number of DRCT Tokens a party will get based on the number of base tokens.  As an example, 1e15 indicates that a party will get 1000 DRCT Tokens based upon 1 ether of wrapped wei. 
    uint public token_ratio;
    //Array of deployed contracts
    address[] public contracts;
    uint[] public startDates;
    address public memberContract;
    mapping(uint => bool) whitelistedTypes;
    mapping(address => uint) public created_contracts;
    mapping(address => uint) public token_dates;
    mapping(uint => address) public long_tokens;
    mapping(uint => address) public short_tokens;

    /*Events*/
    //Emitted when a Swap is created
    event ContractCreation(address _sender, address _created);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
     constructor() public {
        owner = msg.sender;
    }

    /*How do we prevent someone else from starting this?*/
    function init(address _owner) public{
        require(owner == address(0));
        owner = _owner;
    }

    function setMemberContract(address _memberContract) public onlyOwner() {
        memberContract = _memberContract;
    }

    function setWhitelistedMemberTypes(uint[] _memberTypes) public onlyOwner(){
        whitelistedTypes[0] = false;
        for(uint i = 0; i<_memberTypes.length;i++){
            whitelistedTypes[_memberTypes[i]] = true;
        }
    }

    function isWhitelisted(address _member) public view returns (bool){
        MemberCoin_Interface Member = MemberCoin_Interface(memberContract);
        return whitelistedTypes[Member.getMemberType(_member)];
    }
    

    /**
    *@dev Gets long and short token addresses based on specified date
    *@param uint_date
    *@return short and long tokens' addresses
    */
    function getTokens(uint _date) public view returns(address, address){
        return(long_tokens[_date],short_tokens[_date]);
    }

    /*
    * Updates the fee amount
    * @param "_fee": The new fee amount
    */
    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

    /*
    * Sets the deployer address
    * @param "_deployer": The new deployer address
    */
    function setDeployer(address _deployer) public onlyOwner() {
        deployer_address = _deployer;
        deployer = Deployer_Interface(_deployer);
    }

    /*
    * Sets the user_contract address
    * @param "_userContract": The new userContract address
    */
    function setUserContract(address _userContract) public onlyOwner() {
        user_contract = _userContract;
    }

    /*
    *@dev Sets token ratio, swap duration, and multiplier variables for a swap
    *@param _token_ratio the ratio of the tokens
    *@param _duration the duration of the swap, in days
    *@param _multiplier the multiplier used for the swap
    */
    function setVariables(uint _token_ratio, uint _duration, uint _multiplier) public onlyOwner() {
        token_ratio = _token_ratio;
        duration = _duration;
        multiplier = _multiplier;
    }

    /*
    *@dev Sets the addresses of the tokens used for the swap
    *@param _token The address of a token to be used  as collateral
    */
    function setBaseToken(address _token) public onlyOwner() {
        token = _token;
    }

    /**
    *@dev Allows a user to deploy a new swap contract, if they pay the fee
    *@param _start_date the contract start date or date contract was created?
    *@return returns the newly created swap address and calls event 'ContractCreation'
    */
    function deployContract(uint _start_date) public payable returns (address) {
        require(msg.value >= fee && isWhitelisted(msg.sender));
        require(_start_date % 86400 == 0);
        address new_contract = deployer.newContract(msg.sender, user_contract, _start_date);
        contracts.push(new_contract);
        created_contracts[new_contract] = _start_date;
        emit ContractCreation(msg.sender,new_contract);
        return new_contract;
    }

    /**
    *@dev Deploys DRCT tokens for given start date
    *@param _start_date of contract
    *@param long if true
    *@return returns token address of deployed contract
    */
    function deployTokenContract(uint _start_date) public{
        address _token;
        require(_start_date % 86400 == 0);
        require(long_tokens[_start_date] == address(0) && short_tokens[_start_date] == address(0));
        _token = new DRCT_Token(address(this));
        token_dates[_token] = _start_date;
        long_tokens[_start_date] = _token;
        _token = new DRCT_Token(address(this));
        short_tokens[_start_date] = _token;
        token_dates[_token] = _start_date;
        startDates.push(_start_date);
    }

    /*
    *@dev Deploys new tokens on a DRCT_Token contract -- called from within a swap
    *@param _supply The number of tokens to create
    *@param _party the address to send the tokens to
    *@param _start_date the start date of the contract?       
    *@returns ltoken the address of the created DRCT long tokens?
    *@returns stoken the address of the created DRCT short tokens?
    *@returns token_ratio The ratio of the created DRCT token
    */
    function createToken(uint _supply, address _party, uint _start_date) public returns (address, address, uint) {
        require(created_contracts[msg.sender] == _start_date);
        address ltoken = long_tokens[_start_date];
        address stoken = short_tokens[_start_date];
        require(ltoken != address(0) && stoken != address(0));
            DRCT_Token drct_interface = DRCT_Token(ltoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
            drct_interface = DRCT_Token(stoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
        return (ltoken, stoken, token_ratio);
    }
  
    /**
    *@dev Allows the owner to set a new oracle address
    *@param _new_oracle_address 
    */
    function setOracleAddress(address _new_oracle_address) public onlyOwner() {
        oracle_address = _new_oracle_address; 
    }

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Allows the owner to pull contract creation fees
    *@return the withdrawal fee _val and the balance where is the return function?
    */
    function withdrawFees() public onlyOwner(){
        Wrapped_Ether_Interface token_interface = Wrapped_Ether_Interface(token);
        uint _val = token_interface.balanceOf(address(this));
        if(_val > 0){
            token_interface.withdraw(_val);
        }
        owner.transfer(address(this).balance);
     }

    /**
    *@dev fallback function
    */ 
    function() public payable {
    }

    /*
    *@dev Returns a tuple of many private variables
    *@returns oracle_adress": The address of the oracle
    *@returns duration The duration of the swap
    *@returns multiplier The multiplier for the swap
    *@returns token The address of token 
    */
    function getVariables() public view returns (address, uint, uint, address){
        return (oracle_address,duration, multiplier, token);
    }

    /*
    * Pays out to a DRCT token
    * @param "_party": The address being paid
    * @param "_long": Whether the _party is long or not
    */
    function payToken(address _party, address _token_add) public {
        require(created_contracts[msg.sender] > 0);
        DRCT_Token drct_interface = DRCT_Token(_token_add);
        drct_interface.pay(_party, msg.sender);
    }

    /**
    *@dev Counts number of contacts created by this factory
    *@return the number of contracts
    */
    function getCount() public constant returns(uint) {
        return contracts.length;
    }

    /**
    *@dev Counts number of start dates in this factory
    *@return the number of active start dates
    */
    function getDateCount() public constant returns(uint) {
        return startDates.length;
    }
}
