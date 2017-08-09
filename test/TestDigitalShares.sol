pragma solidity ^0.4.13;

import "../contracts/DigitalShares.sol";

contract TestDigitalShares is DigitalShares {

	function TestDigitalShares(uint128 _totalShares) DigitalShares(_totalShares) {
	}

	function getCalculatedShares() constant returns (uint128) {
		int256 shares = 0;
		for (uint256 i = 0; i < snapshots.length; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[msg.sender];
		}
		return uint128(shares);
	}

	function getCalculatedSharesUsingPayed() constant returns (uint128) {
		int256 shares = 0;
		for (uint256 i = payed[msg.sender]; i < snapshots.length; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[msg.sender];
		}
		return uint128(shares);
	}

	function getShapshotShares(uint index) constant returns (int256) {
		return snapshots[index].shares[msg.sender];
	}

	function getUnpayedWei(address holder) constant returns (uint256) {
		return unpayedWei[holder];
	}

	function getUndistributed() constant returns (uint256) {
		return undistributed;
	}
}