pragma solidity ^0.4.15;

import "../contracts/DigitalShares.sol";

contract TestDigitalShares is DigitalShares {

	function TestDigitalShares(uint256 _totalShares) DigitalShares(_totalShares) {
	}

	function getCalculatedShares() constant returns (uint256) {
		int256 shares = 0;
		for (uint256 i = 0; i < distributions.length; i++) {
			Snapshot storage snapshot = distributions[i];
			shares += snapshot.shares[msg.sender];
		}
		assert(shares >= 0);
		return uint256(shares);
	}

	function getCalculatedSharesUsingPaid() constant returns (uint256) {
		int256 shares = 0;
		for (uint256 i = lastPaidDistribution[msg.sender]; i < distributions.length; i++) {
			Snapshot storage snapshot = distributions[i];
			shares += snapshot.shares[msg.sender];
		}
		assert(shares >= 0);
		return uint256(shares);
	}

	function getShapshotShares(uint index) constant returns (int256) {
		return distributions[index].shares[msg.sender];
	}

	function getUnpaidWei(address holder) constant returns (uint256) {
		return unpaidWei[holder];
	}

	function getReserved() constant returns (uint256) {
		return reservedWei;
	}
}