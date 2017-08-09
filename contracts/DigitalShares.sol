pragma solidity ^0.4.13;

import "zeppelin/Ownable.sol";
import "zeppelin/SafeMath.sol";

contract DigitalShares is Ownable {
	using SafeMath for uint256;

	struct Snapshot {
		mapping (address => int256) shares;
		uint256 amountInWei;
	}
	Snapshot[] snapshots;
	uint256 totalShares;
	uint256 undistributed;
	mapping(address => uint128) balance;
	mapping(address => uint256) payed;
	mapping(address => uint256) unpayedWei;

	event Distributed(uint256 amount);
	event FundsReceived(address indexed from, uint256 amount);
	event SharesSent(address indexed from, address indexed to, uint128 amount);
	event Payed(uint256 amount);

	function DigitalShares(uint128 _totalShares) {
		require(_totalShares > 0);
		require(_totalShares <= 0xffffffffffffffffffffffffffffffff);
		totalShares = _totalShares;
		snapshots.push(Snapshot({amountInWei: 0}));
		Snapshot storage snapshot = snapshots[snapshots.length - 1];
		snapshot.shares[tx.origin] = _totalShares;
		balance[tx.origin] = _totalShares;
	}

	function transferShares(address _to, uint128 _amount) external returns (bool) {
		if (_to == address(0)) return false;
		if (_amount == 0) return false;

		uint256 shares = balance[msg.sender];
		if (shares >= _amount) {
			Snapshot storage snapshot = snapshots[snapshots.length - 1];
			snapshot.shares[msg.sender] -= _amount;
			balance[msg.sender] -= _amount;
			snapshot.shares[_to] += _amount;
			balance[_to] += _amount;
			SharesSent(msg.sender, _to, _amount);
			return true;
		} else {
			return false;
		}
	}

	function distribute(uint256 _amount) external onlyOwner {
		require(_amount > 0);

		if (_amount <= getDistributionBalance()) {
			Snapshot storage snapshot = snapshots[snapshots.length - 1];
			snapshot.amountInWei = _amount;
			snapshots.push(Snapshot({ amountInWei: 0}));
			undistributed = undistributed.add(_amount);
			Distributed(_amount);
		}
	}

	function getDistributionBalance() constant returns (uint256) {
	    return this.balance.sub(undistributed);
	}

	/**
	 * Withdraw all
	 */
	function withdraw() external returns (bool) {
		return performWithdraw(snapshots.length - 1);
	}
	/**
	 * This function withdraws ether up to 'snapshotIndex' snapshot.
	 * There can be many snapshots and we need to save payout at each snapshot, so we can run out of gas. So this function is needed to partially withdraw funds.
	 */
	function withdrawUpTo(uint256 _snapshotIndex) external returns (bool) {
		require(_snapshotIndex <= snapshots.length - 1);
		performWithdraw(_snapshotIndex);
	}

	function performWithdraw(uint256 _snapshotIndex) internal returns (bool) {
		uint256 numerator = 0;
		int256 shares = 0;
		for (uint256 i = payed[msg.sender]; i < _snapshotIndex; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[msg.sender];
			if (shares > 0) { // just to be sure we can cast to uint256
				numerator = numerator.add(snapshot.amountInWei.mul(uint256(shares)));
			}
			snapshot.shares[msg.sender] = 0;
		}
		snapshots[_snapshotIndex].shares[msg.sender] += shares;

		numerator = numerator.add(unpayedWei[msg.sender]);
		if (numerator > 0) {
			uint256 amount = numerator / totalShares;
			unpayedWei[msg.sender] = numerator % totalShares;

			assert(amount <= this.balance);

			payed[msg.sender] = _snapshotIndex;
			undistributed = undistributed.sub(amount);
		    if (msg.sender.send(amount)) {
		    	Payed(amount);
		    } else {
		    	revert();
		    }
		}
	}

	function getDividends() constant returns (uint256) {
		uint256 numerator = 0;
		int256 shares = 0;
		for (uint256 i = payed[msg.sender]; i < snapshots.length - 1; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[msg.sender];
			if (shares > 0) {
				numerator = numerator.add(snapshot.amountInWei.mul(uint256(shares)));
			}
		}
		numerator = numerator.add(unpayedWei[msg.sender]);
		return numerator / totalShares;
	}

	function getSnapshotCount() constant returns (uint256) {
		return snapshots.length;
	}

	function getShares() constant returns (uint128) {
		return balance[msg.sender];
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}
