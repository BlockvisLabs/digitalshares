pragma solidity ^0.4.11;

import "./SafeMath.sol";

contract MyContract {
	using SafeMath for uint256;
	address public owner;

	uint256 public totalShares;
	uint256 dividendReserve;

	mapping (address => uint256) shares;
	mapping (address => uint256) dividends;
	mapping (address => bool) stocks;

	address[] holders;
	mapping (address => uint) holderIndex; // holderIndex is 1 based because by default all addresses have 0 index

	event DividendsDistributed(uint when, uint256 amount);
	event FundsReceived(address indexed from, uint256 amount);
	event NewHolder(address indexed holder);
	event HolderRemoved(address indexed holder);
	event SharesSent(address indexed from, address indexed to, uint256 amount);
	event SharesAdded(address indexed to, uint256 amount);

	function MyContract() {
		owner = msg.sender;
		totalShares = 10000;
		shares[owner] = totalShares;
		holders.push(owner);
		holderIndex[owner] = 1;
	}

	modifier onlyowner() {
		require(msg.sender == owner);
		_;
	}

	function sendShares(address to, uint amount) {
		require(to != 0x0);
		require(amount > 0);
		require(amount <= totalShares);
		require(shares[msg.sender] >= amount);

		bool newHolder = (shares[to] == 0);

		shares[msg.sender] = shares[msg.sender].sub(amount);
		shares[to] = shares[to].add(amount);

		if (shares[msg.sender] == 0) {
			removeHolder(msg.sender);
		}

		if (newHolder) {
			addHolder(to);
		}
		SharesSent(msg.sender, to, amount);
	}

	function addShare(address to, uint256 amount) onlyowner {
		require(to != 0x0);
		require(amount > 0);
		uint256 currentHold = shares[to];
		bool newHolder = (currentHold == 0);
		shares[to] = currentHold.add(amount);
		if (newHolder == true) {
			addHolder(to);
		}
		totalShares = totalShares.add(amount);
		SharesAdded(to, amount);
	}

	function addShares(address[] holders, uint256[] amounts) onlyowner  {
		require(holders.length > 0);
		require(holders.length == amounts.length);
		uint256 sharesAdded = 0;
		for (uint256 i = 0; i < holders.length; i++) {
			address holder = holders[i];
			uint256 amount = amounts[i];
			require(holder != 0x0);
			require(amount > 0);
			sharesAdded = sharesAdded.add(amount);
			uint256 currentHold = shares[holder];
			bool newHolder = (currentHold == 0);
			shares[holder] = currentHold.add(amount);
			if (newHolder == true) {
				addHolder(holder);
			}
			SharesAdded(holder, amount);
		}
		totalShares = totalShares.add(sharesAdded);
	}

	function addHolder(address toAdd) internal {
		holders.push(toAdd);
		holderIndex[toAdd] = holders.length;
		NewHolder(toAdd);
	}

	function removeHolder(address toRemove) internal {
		require(holders.length > 0);
		uint256 index = holderIndex[toRemove] - 1;
		if (index >= 0) {
			holderIndex[toRemove] = 0;
			uint256 indexOfLast = holders.length - 1;
			if (indexOfLast != toRemove) {
				address lastHolder = holders[indexOfLast];
	 			holders[index] = lastHolder;
				holderIndex[lastHolder] = index + 1;
			}
			delete holders[indexOfLast];
			holders.length--;
		}
		HolderRemoved(toRemove);
	}

	function setOwner(address newOwner) onlyowner {
		require(newOwner != 0x0);
		owner = newOwner;
	}

	/**
	 * function which distributes ether between holders
	 * @param  amount       onlyowner returns (uint256 [description]
	 * @return undistributed amount because of rounding errors [description]
	 */
	function distributeDividends(uint256 amount) onlyowner returns (uint256) {
		require(amount > 0);
		require(holders.length > 0);
		require(amount <= this.balance);
		uint256 totalDistributed = 0;
		for (uint256 i = 0; i < holders.length; i++) {
			address holder = holders[i];
			if (stocks[holder] == false) {
				uint holderShare = shares[holder];
				if (holderShare > 0) {
					uint256 holderAmount = (holderShare * amount) / totalShares;
					totalDistributed += holderAmount;
					dividends[holder] += holderAmount;
				}
			}
		}
		dividendReserve += totalDistributed;
		return amount.sub(totalDistributed);
	}

	function withdraw() {
		address holder = msg.sender;
	    uint256 amount = dividends[holder];

	    require(amount != 0);
	    require(this.balance >= amount);

	    dividendReserve = dividendReserve.sub(amount);
	    dividends[holder] = 0;

	    assert(holder.send(amount));
	}

	function kill() onlyowner {
		selfdestruct(owner);
	}

	// function getShares(address holder) constant returns (uint256) {
	// 	return shares[holder];
	// }

	function getShares() constant returns (uint256) {
		return shares[msg.sender];
	}

	function getDividends() constant returns (uint256) {
		return dividends[msg.sender];
	}

	// function getDividends(address holder) constant returns (uint256) {
	// 	return dividends[holder];
	// }

	function isStock(address stock) constant returns (bool) {
		return stocks[stock];
	}

	function getHolders() constant returns (address[]) {
		return holders;
	}

	function registerStock(address stock) onlyowner {
		stocks[stock] = true;
	}

	function unregisterStock(address stock) onlyowner {
		stocks[stock] = false;
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}