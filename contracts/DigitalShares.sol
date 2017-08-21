pragma solidity ^0.4.15;

import "zeppelin/Ownable.sol";
import "zeppelin/SafeMath.sol";
import "zeppelin/StandardToken.sol";

contract DigitalShares is Ownable, StandardToken {
	using SafeMath for uint256;

	uint256 constant MAX_INT256 = uint256(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

	struct Snapshot {
		mapping (address => int256) shares;
		uint256 amountInWei;
	}
	uint256 reservedWei;
	Snapshot[] snapshots;
	mapping(address => uint256) payed;
	mapping(address => uint256) unpayedWei;

	event Distributed(uint256 amount);
	event FundsReceived(address indexed from, uint256 amount);
	event Payed(uint256 amount);

	function DigitalShares(uint256 _totalSupply) {
		require(_totalSupply > 0);
		require(_totalSupply <= MAX_INT256);
		totalSupply = _totalSupply;
		balances[tx.origin] = _totalSupply;
		snapshots.push(Snapshot({amountInWei: 0}));
		Snapshot storage snapshot = snapshots[snapshots.length - 1];
		snapshot.shares[tx.origin] = int256(_totalSupply);
	}

	function transfer(address _to, uint256 _value) returns (bool) {
		if (_to == address(0)) return false;
		if (_value == 0) return false;
		if (_value > MAX_INT256) return false;

		if (super.transfer(_to, _value)) {
			Snapshot storage snapshot = snapshots[snapshots.length - 1];
			snapshot.shares[msg.sender] -= int256(_value);
			snapshot.shares[_to] += int256(_value);
			return true;
		}
		else {
			return false;
		}
	}

	function transferFrom(address from, address to, uint256 value) returns (bool) {
		if (value > MAX_INT256) return false;
		if (super.transferFrom(from, to, value)) {
			Snapshot storage snapshot = snapshots[snapshots.length - 1];
			snapshot.shares[from] -= int256(value);
			snapshot.shares[to] += int256(value);
		}
	}

	function distribute(uint256 _amount) external onlyOwner {
		require(_amount > 0);

		if (_amount <= this.balance.sub(reservedWei)) {
			Snapshot storage snapshot = snapshots[snapshots.length - 1];
			snapshot.amountInWei = _amount;
			snapshots.push(Snapshot({ amountInWei: 0}));
			reservedWei = reservedWei.add(_amount);
			Distributed(_amount);
		}
	}

	function getDistributionBalance() constant returns (uint256) {
	    return this.balance.sub(reservedWei);
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
			uint256 amount = numerator / totalSupply;
			unpayedWei[msg.sender] = numerator % totalSupply;

			assert(amount <= this.balance);

			payed[msg.sender] = _snapshotIndex;
			reservedWei = reservedWei.sub(amount);
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
		return numerator / totalSupply;
	}

	function getSnapshotCount() constant returns (uint256) {
		return snapshots.length;
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}
