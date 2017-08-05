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
	mapping(address => uint256) balance;
	mapping(address => uint256) payed;
	mapping(address => uint256) unpayedWei;

	event DividendsDistributed(uint256 amount);
	event FundsReceived(address indexed from, uint256 amount);
	event SharesSent(address indexed from, address indexed to, uint128 amount);
	event Payed(uint256 amount);

	function DigitalShares(uint128 _totalShares) {
		require(_totalShares > 0);
		totalShares = _totalShares;
		snapshots.push(Snapshot({amountInWei: 0}));
		Snapshot storage snapshot = snapshots[snapshots.length - 1];
		snapshot.shares[tx.origin] = _totalShares;
		balance[tx.origin] = _totalShares;
	}

	function transferShares(address _to, uint128 _amount) external returns (bool) {
		require(_to != address(0));
		require(_amount > 0);

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
		require(_amount <= this.balance);

		Snapshot storage snapshot = snapshots[snapshots.length - 1];
		snapshot.amountInWei = _amount;
		snapshots.push(Snapshot({ amountInWei: 0}));
		DividendsDistributed(_amount);
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
		require(_snapshotIndex < snapshots.length - 1);
		performWithdraw(_snapshotIndex);
	}

	function performWithdraw(uint256 _snapshotIndex) internal returns (bool) {
		uint256 divider = multiply(msg.sender, _snapshotIndex) + unpayedWei[msg.sender];
		if (divider > 0) {
			uint256 amount = divider / totalShares;
			unpayedWei[msg.sender] = divider % totalShares;
			assert(amount <= this.balance);
			payed[msg.sender] = _snapshotIndex;
		    if (msg.sender.send(amount)) {
		    	Payed(amount);
		    } else {
		    	revert();
		    }
		}
	}

	function multiply(address _holder, uint256 _toIndex) constant private returns (uint256) {
		uint256 payedUpTo = payed[_holder];
		uint256 result = 0;
		int256 shares = 0;
		for (uint256 i = 0; i < _toIndex; i++) {
			Snapshot storage snapshot = snapshots[i];
			shares += snapshot.shares[_holder];
			if (i >= payedUpTo && shares > 0) {
				result += (snapshot.amountInWei * uint256(shares));
			}
		}
		return result;
	}

	function getDividends() constant returns (uint256) {
		uint256 divider = multiply(msg.sender, snapshots.length - 1) + unpayedWei[msg.sender];
		uint256 amount = divider / totalShares;
		return amount;
	}

	function getSnapshotCount() constant returns (uint256) {
		return snapshots.length;
	}

	function getShares() constant returns (uint256) {
		return balance[msg.sender];
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}
