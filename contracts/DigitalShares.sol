pragma solidity ^0.4.11;

import "zeppelin/Ownable.sol";
import "zeppelin/SafeMath.sol";
import "zeppelin/ReentrancyGuard.sol";
import "./ShareSnapshot.sol";
import "./OwnerHolder.sol";

contract DigitalShares is Ownable, ReentrancyGuard {
	using SafeMath for uint256;

	address[] snapshots;
	address ownerHolder;
	address latestSnapshot;
	mapping(address => uint256) payed;

	event DividendsDistributed(uint256 amount);
	event FundsReceived(address indexed from, uint256 amount);
	event SharesSent(address indexed from, address indexed to, uint128 amount);
	event SharesAdded(address indexed to, uint128 amount);
	event Payed(uint256 amount);

	modifier onlyInitialized() {
		if (ownerHolder != address(0)) {
			_;
		}
	}

	function initialize() onlyOwner {
		if (ownerHolder != address(0)) {
			return;
		}
		ownerHolder = new OwnerHolder();
		latestSnapshot = new ShareSnapshot(ownerHolder, 0);
		snapshots.push(latestSnapshot);
	}

	function getShareBalance(address holder) constant returns (uint256) {
		int256 shares = 0;
		uint256 n = snapshots.length;
		for (uint256 i = 0; i < n; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			shares += snapshot.getShares(holder);
		}
		assert(shares >= 0);
		return uint256(shares);
	}

	function isStock(address stock) constant returns (bool) {
		int256 result = 0;
		uint256 n = snapshots.length;
		for (uint256 i = 0; i < n; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			result += snapshot.getStock(stock);
		}
		return result > 0;
	}

	function getLatestSnapshot() internal constant returns (address) {
		return snapshots[snapshots.length - 1];
	}

	function sendShares(address to, uint128 amount) external onlyInitialized nonReentrant {
		require(to != address(0));
		require(amount > 0);

		uint256 shares = getShareBalance(msg.sender);
		if (shares >= amount) {
			ShareSnapshot snapshot = ShareSnapshot(latestSnapshot);
			snapshot.sendShares(msg.sender, to, amount);

			SharesSent(msg.sender, to, amount);
		}
	}

	function addShare(address to, uint128 amount) onlyOwner onlyInitialized nonReentrant {
		require(to != address(0));
		require(amount > 0);

		ShareSnapshot snapshot = ShareSnapshot(latestSnapshot);
		snapshot.addShares(to, amount);

		SharesAdded(to, amount);
	}

	function distributeDividends(uint256 amount) external onlyOwner onlyInitialized nonReentrant {
		require(amount > 0);
		require(amount <= this.balance);

		ShareSnapshot snapshot = ShareSnapshot(latestSnapshot);
		snapshot.lock(amount);
		latestSnapshot = new ShareSnapshot(ownerHolder, snapshot.totalShares());
		snapshots.push(latestSnapshot);
		DividendsDistributed(amount);
	}

	/**
	 * Withdraw all
	 */
	function withdraw() external onlyInitialized nonReentrant {
		performWithdraw(snapshots.length - 1); // last snapshot is always unlocked
	}
	/**
	 * This function withdraws ether up to 'snapshotIndex' snapshot.
	 * There can be many snapshots and we need to save payout at each snapshot, so we can run out of gas. So this function is needed to partially withdraw funds.
	 */
	function withdrawUpTo(uint256 snapshotIndex) external onlyInitialized nonReentrant {
		performWithdraw(snapshotIndex);
	}

	function performWithdraw(uint256 snapshotIndex) private {
		require(snapshotIndex < snapshots.length);
		uint256 amount = 0;
		int256 shareBalance = 0;
		int256 stockBalance = 0;
		int256 shares;
		int256 stock;
		uint256 amountInWei;
		uint256 totalShares;
		bool locked;
		uint256 payedUpToSnapshot = payed[msg.sender];
		for (uint256 i = 0; i < snapshotIndex; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			(shares, stock, amountInWei, totalShares, locked) = snapshot.getData(msg.sender);
			shareBalance += shares;
			stockBalance += stock;
			if (i >= payedUpToSnapshot && shareBalance > 0 && stockBalance == 0 && locked) {
				uint256 snapshotPayout = (uint256(shareBalance) * amountInWei) / totalShares;
				amount += snapshotPayout;
			}
		}
		assert(amount > 0);
		assert(amount <= this.balance);
		payed[msg.sender] = snapshotIndex;

	    if (!msg.sender.send(amount)) {
	    	revert();
	    } else {
	    	Payed(amount);
	    }
	}

	function getDividends() constant returns (uint256) {
		uint256 amount = 0;
		int256 shareBalance = 0;
		int256 stockBalance = 0;
		int256 shares;
		int256 stock;
		uint256 amountInWei;
		uint256 totalShares;
		bool locked;
		uint256 payedUpToSnapshot = payed[msg.sender];
		for (uint256 i = 0; i < snapshots.length; i++) {
			ShareSnapshot snapshot = ShareSnapshot(snapshots[i]);
			(shares, stock, amountInWei, totalShares, locked) = snapshot.getData(msg.sender);
			shareBalance += shares;
			stockBalance += stock;
			if (i >= payedUpToSnapshot && shareBalance > 0 && stockBalance == 0 && locked) {
				uint256 snapshotPayout = (uint256(shareBalance) * amountInWei) / totalShares;
				amount += snapshotPayout;
			}
		}
		return amount;
	}

	function getSnapshotCount() constant returns (uint256) {
		return snapshots.length;
	}

	function getShares() constant returns (uint256) {
		return getShareBalance(msg.sender);
	}

	function registerStock(address stock) onlyOwner onlyInitialized {
		if (isStock(stock) == false) {
			ShareSnapshot(latestSnapshot).registerStock(stock);
		}
	}

	function unregisterStock(address stock) onlyOwner onlyInitialized {
		if (isStock(stock) == true) {
			ShareSnapshot(latestSnapshot).unregisterStock(stock);
		}
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}