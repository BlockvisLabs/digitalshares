pragma solidity ^0.4.15;

import "../contracts/DigitalShares.sol";

contract TestDigitalShares is DigitalShares {

	function TestDigitalShares(uint256 _totalShares) DigitalShares(_totalShares) {
	}

	function getCalculatedShares() constant returns (uint256) {
		int256 shares = 0;
		for (uint256 i = 0; i < snapshots.length; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[msg.sender];
		}
		assert(shares >= 0);
		return uint256(shares);
	}

	function getCalculatedSharesUsingPayed() constant returns (uint256) {
		int256 shares = 0;
		for (uint256 i = payed[msg.sender]; i < snapshots.length; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[msg.sender];
		}
		assert(shares >= 0);
		return uint256(shares);
	}

	function getShapshotShares(uint index) constant returns (int256) {
		return snapshots[index].shares[msg.sender];
	}

	function getUnpayedWei(address holder) constant returns (uint256) {
		return unpayedWei[holder];
	}

	function getReserved() constant returns (uint256) {
		return reservedWei;
	}
}