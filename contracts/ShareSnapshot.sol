pragma solidity ^0.4.11;

import "./OwnerHolder.sol";

contract ShareSnapshot {
	address ownerHolder;
	mapping (address => int256) shares;
	mapping (address => bool) payed;
	mapping (address => int256) stocks;
	uint256 public totalShares;
	uint256 public amountInWei;
	bool locked;

	function ShareSnapshot(address ownerHolder_, uint256 totalShares_) {
		ownerHolder = ownerHolder_;
		totalShares = totalShares_;
	}

	modifier onlyowner() {
		OwnerHolder owner = OwnerHolder(ownerHolder);
		require(owner.owner() == msg.sender);
		_;
	}

	modifier notlocked() {
		require(locked == false);
		_;
	}

	function getShares(address holder) constant returns (int256) {
		return shares[holder];
	}

	function sendShares(address from, address to, int256 amount) onlyowner notlocked {
		shares[from] -= amount;
		shares[to] += amount;
	}

	function addShares(address to, int256 amount) onlyowner notlocked {
		require(amount > 0);
		totalShares += uint256(amount);
		shares[to] += amount;
	}

	function lock(uint256 amount) onlyowner notlocked {
		amountInWei = amount;
		locked = true;
	}

	function registerStock(address stock) onlyowner notlocked {
		stocks[stock] = 1;
	}

	function unregisterStock(address stock) onlyowner notlocked {
		stocks[stock] = -1;
	}

	function getStock(address stock) constant returns (int256) {
		return stocks[stock];
	}

	function setPayed(address holder, bool isPayed) onlyowner {
		payed[holder] = isPayed;
	}

	function canPayTo(address holder) constant returns (bool) {
		return locked == true && payed[holder] == false;
	}


}