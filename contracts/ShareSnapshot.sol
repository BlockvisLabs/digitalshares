pragma solidity ^0.4.11;

import "./OwnerHolder.sol";

contract ShareSnapshot {
	address ownerHolder;
	mapping (address => int256) shares;
	mapping (address => int256) stocks;
	uint256 public totalShares;
	uint256 amountInWei;
	bool locked;

	function ShareSnapshot(address ownerHolder_, uint256 totalShares_) {
		ownerHolder = ownerHolder_;
		totalShares = totalShares_;
	}

	modifier onlyOwner() {
		OwnerHolder owner = OwnerHolder(ownerHolder);
		require(owner.owner() == msg.sender);
		_;
	}

	modifier notLocked() {
		require(locked == false);
		_;
	}

	function getShares(address holder) constant returns (int256) {
		return shares[holder];
	}

	function sendShares(address from, address to, uint128 amount) onlyOwner notLocked {
		shares[from] -= amount;
		shares[to] += amount;
	}

	function addShares(address to, uint128 amount) onlyOwner notLocked {
		totalShares += amount;
		shares[to] += amount;
	}

	function lock(uint256 amount) onlyOwner notLocked {
		amountInWei = amount;
		locked = true;
	}

	function registerStock(address stock) onlyOwner notLocked {
		stocks[stock] = 1;
	}

	function unregisterStock(address stock) onlyOwner notLocked {
		stocks[stock] = -1;
	}

	function getStock(address stock) constant returns (int256) {
		return stocks[stock];
	}

	function getData(address _addr) constant returns(int256, int256, uint256, uint256, bool) {
		return (shares[_addr], stocks[_addr], amountInWei, totalShares, locked);
	}
}