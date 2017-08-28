pragma solidity ^0.4.15;

import 'DigitalShares.sol';

contract DigitalSharesExchange is DigitalShares {

	/**
	 * @dev This mapping contains blocked token for exchange. Owner of tokens cannot revoke them, only exchange can
	 * @param  {[type]} address [description]
	 * @return {[type]}         [description]
	 */
	mapping (address => mapping (address => uint256)) blocked;
	/**
	 * @dev This mapping holds amount of token which are blocked for all exchanges
	 * @param  {[type]} address [description]
	 * @return {[type]}         [description]
	 */
	mapping (address => uint256) blockedBalances;

	event SharesAcquired(address indexed owner, address indexed exchange, uint256 value);
	event SharesReleased(address indexed owner, address indexed exchange, uint256 value);

	function DigitalSharesExchange(uint256 _totalShares) DigitalShares(_totalShares) {
	}

	modifier hasEnoughBalance(address _owner, uint256 _value) {
		var availableBalance = balances[_owner].sub(blockedBalances[_owner]);
		require(availableBalance >= _value);
		_;
	}

	function transfer(address _to, uint256 _value) hasEnoughBalance(msg.sender, _value) returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) hasEnoughBalance(_from, _value) returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function transferToExchange(address _exchange, uint256 _value) hasEnoughBalance(msg.sender, _value) returns (bool) {
		blocked[msg.sender][_exchange] = blocked[msg.sender][_exchange].add(_value);
		blockedBalances[msg.sender] = blockedBalances[msg.sender].add(_value);
		SharesAcquired(msg.sender, _exchange, _value);
		return true;
	}

	function exchangeTransfer(address _from, address _to, uint256 _value) returns (bool) {
		require(blocked[_from][msg.sender] >= _value);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		Snapshot storage snapshot = distributions[distributions.length - 1];
		snapshot.shares[_from] -= int256(_value);
		snapshot.shares[_to] += int256(_value);

		blocked[_from][msg.sender] = blocked[_from][msg.sender].sub(_value);
		blocked[_to][msg.sender] = blocked[_to][msg.sender].add(_value);

		blockedBalances[_from] = blockedBalances[_from].sub(_value);
		blockedBalances[_to] = blockedBalances[_to].add(_value);

		Transfer(_from, _to, _value);
		return true;
	}

	function releaseShares(address _to, uint256 _value) returns (bool) {
		require(blocked[_to][msg.sender] >= _value);

		blocked[_to][msg.sender] = blocked[_to][msg.sender].sub(_value);
		blockedBalances[_to] = blockedBalances[_to].sub(_value);

		SharesReleased(_to, msg.sender, _value);
		return true;
	}

	function exchangeAllowance(address _owner, address _exchange) constant returns (uint256) {
		return blocked[_owner][_exchange];
	}

	function getAvailableBalance() constant returns (uint256) {
		return balances[msg.sender].sub(blockedBalances[msg.sender]);
	}



}