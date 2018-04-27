pragma solidity 0.4.23;

import "./DigitalSecuritiesToken.sol";


contract DigitalSecuritiesExchangeToken is DigitalSecuritiesToken {

    /**
     * @dev This mapping contains reserved token for exchange. Token ownerns cannot revoke them, only exchange can
     * @param  {[type]} address [description]
     * @return {[type]}         [description]
     */
    mapping (address => mapping (address => uint256)) public reserved;
    /**
     * @dev This mapping holds amount of token which are reserved for all exchanges
     * @param  {[type]} address [description]
     * @return {[type]}         [description]
     */
    mapping (address => uint256) public totalReserved;

    event SharesAcquired(address indexed owner, address indexed exchange, uint256 value);
    event SharesReleased(address indexed owner, address indexed exchange, uint256 value);

    constructor(uint256 _totalShares) public DigitalSecuritiesToken(_totalShares) {
    }

    modifier hasEnoughBalance(address _owner, uint256 _value) {
        require(balances[_owner].sub(totalReserved[_owner]) >= _value);
        _;
    }

    function transfer(address _to, uint256 _value) public hasEnoughBalance(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public hasEnoughBalance(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function transferToExchange(address _exchange, uint256 _value) public hasEnoughBalance(msg.sender, _value) returns (bool) {
        reserved[msg.sender][_exchange] = reserved[msg.sender][_exchange].add(_value);
        totalReserved[msg.sender] = totalReserved[msg.sender].add(_value);
        emit SharesAcquired(msg.sender, _exchange, _value);
        return true;
    }

    function exchangeTransfer(address _from, address _to, uint256 _value) public returns (bool) {
        require(reserved[_from][msg.sender] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        reserved[_from][msg.sender] = reserved[_from][msg.sender].sub(_value);
        reserved[_to][msg.sender] = reserved[_to][msg.sender].add(_value);

        totalReserved[_from] = totalReserved[_from].sub(_value);
        totalReserved[_to] = totalReserved[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function releaseShares(address _to, uint256 _value) public returns (bool) {
        require(reserved[_to][msg.sender] >= _value);

        reserved[_to][msg.sender] = reserved[_to][msg.sender].sub(_value);
        totalReserved[_to] = totalReserved[_to].sub(_value);

        emit SharesReleased(_to, msg.sender, _value);
        return true;
    }

    function exchangeAllowance(address _owner, address _exchange) public view returns (uint256) {
        return reserved[_owner][_exchange];
    }

    function getAvailableBalance() public view returns (uint256) {
        return balances[msg.sender].sub(totalReserved[msg.sender]);
    }
}
