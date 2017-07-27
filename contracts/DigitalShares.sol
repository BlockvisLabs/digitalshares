pragma solidity ^0.4.11;

import "./SafeMath.sol";
import "./ShareSnapshot.sol";
import "./OwnerHolder.sol";

contract DigitalShares {
	using SafeMath for uint256;
	address public owner;

	address[] snapshots;
	address ownerHolder;

	bool initialized;

	event DividendsDistributed(uint when, uint256 amount);
	event FundsReceived(address indexed from, uint256 amount);
	event SharesSent(address indexed from, address indexed to, uint128 amount);
	event SharesAdded(address indexed to, uint128 amount);

	function DigitalShares() {
		owner = msg.sender;
	}

	modifier onlyowner() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyinitialized() {
		require(initialized == true);
		_;
	}

	function initialize() onlyowner {
		require(initialized == false);
		initialized = true;
		ownerHolder = new OwnerHolder();
		snapshots.push(new ShareSnapshot(ownerHolder, 0));
	}

	function getBalance(address holder) constant returns (uint256) {
		int256 shares = 0;
		for (uint256 i = 0; i < snapshots.length; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			shares += snapshot.getShares(holder);
		}
		assert(shares >= 0);
		return uint256(shares);
	}

	function isStock(address stock) constant returns (bool) {
		int256 result = 0;
		for (uint256 i = 0; i < snapshots.length; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			result += snapshot.getStock(stock);
		}
		return result > 0;
	}

	function getLatestSnapshot() constant returns (address) {
		return snapshots[snapshots.length - 1];
	}

	function sendShares(address to, uint128 amount) onlyinitialized {
		require(to != address(0));
		require(amount > 0);

		uint256 shares = getBalance(msg.sender);
		require(shares >= amount);

		ShareSnapshot snapshot = ShareSnapshot(getLatestSnapshot());

		snapshot.sendShares(msg.sender, to, amount);

		SharesSent(msg.sender, to, amount);
	}

	function addShare(address to, uint128 amount) onlyowner onlyinitialized {
		require(to != address(0));
		require(amount > 0);

		ShareSnapshot snapshot = ShareSnapshot(getLatestSnapshot());
		snapshot.addShares(to, amount);

		SharesAdded(to, amount);
	}

	function setOwner(address newOwner) onlyowner {
		require(newOwner != address(0));
		owner = newOwner;
	}

	function distributeDividends(uint256 amount) onlyowner onlyinitialized {
		require(amount > 0);
		require(amount <= this.balance);

		ShareSnapshot snapshot = ShareSnapshot(getLatestSnapshot());
		snapshot.lock(amount);
		snapshots.push(new ShareSnapshot(ownerHolder, snapshot.totalShares()));
		DividendsDistributed(now, amount);
	}

	/**
	 * Withdraw all
	 */
	function withdraw() onlyinitialized {
		withdrawUpTo(snapshots.length - 1); // last snapshot is always unlocked
	}
	/**
	 * This function withdraws ether up to 'snapshotIndex' snapshot.
	 * There can be many snapshots and we need to save payout at each snapshot, so we can run out of gas. So this function is needed to partially withdraw funds.
	 */
	function withdrawUpTo(uint256 snapshotIndex) onlyinitialized {
		require(snapshotIndex < snapshots.length);
		uint256 amount = 0;
		int256 shares = 0;
		int256 stock = 0;
		address[] memory payedSnapshots = new address[](snapshots.length);
		uint256 payedCount = 0;
		for (uint256 i = 0; i < snapshotIndex; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			shares += snapshot.getShares(msg.sender);
			assert(shares >= 0);
			stock += snapshot.getStock(msg.sender);
			assert(stock >= 0);
			if (snapshot.canPayTo(msg.sender) && stock == 0 && shares > 0) {
				snapshot.setPayed(msg.sender, true);
				payedSnapshots[payedCount] = snapshots[i];
				payedCount++;
				uint256 snapshotPayout = (uint256(shares) * snapshot.amountInWei()) / snapshot.totalShares();
				amount += snapshotPayout;
			}
		}
		assert(amount > 0);
		assert(amount <= this.balance);

	    if (!msg.sender.send(amount)) {
	    	for (uint256 j = 0; j < payedCount; j++) {
	    		ShareSnapshot(payedSnapshots[j]).setPayed(msg.sender, false);
	    	}
	    }
	}

	function getDividends() constant returns (uint256) {
		uint256 amount = 0;
		int256 shares = 0;
		int256 stock = 0;
		for (uint256 i = 0; i < snapshots.length; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			shares += snapshot.getShares(msg.sender);
			assert(shares >= 0);
			stock += snapshot.getStock(msg.sender);
			if (snapshot.canPayTo(msg.sender) && stock == 0) {
				uint256 snapshotPayout = (uint256(shares) * snapshot.amountInWei()) / snapshot.totalShares();
				amount += snapshotPayout;
			}
		}
		assert(amount > 0);
		return amount;
	}

	function getSnapshotCount() constant returns (uint256) {
		return snapshots.length;
	}

	function getShares() constant returns (uint256) {
		return getBalance(msg.sender);
	}

	function registerStock(address stock) onlyowner onlyinitialized {
		ShareSnapshot(getLatestSnapshot()).registerStock(stock);
	}

	function unregisterStock(address stock) onlyowner onlyinitialized {
		ShareSnapshot(getLatestSnapshot()).unregisterStock(stock);
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}