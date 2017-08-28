pragma solidity 0.4.15;

import "zeppelin/Ownable.sol";
import "zeppelin/SafeMath.sol";
import "zeppelin/StandardToken.sol";

contract DigitalShares is Ownable, StandardToken {
	using SafeMath for uint256;

	uint256 constant MAX_INT256 = uint256(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
	/**
	 * The contract stores an array of Snapshots.
	 * One snapshot corresponds to one profit distribution, except the last one. The last snapshot holds share transfers from the last profit distribution.
	 */
	struct Snapshot {
		/**
		 * Holds a share distribution if differential form
		 * @param  {[type]} address [description]
		 * @return {[type]}         [description]
		 */
		mapping (address => int256) shares;
		/**
		 * Stores amount of wei required to distribute
		 */
		uint256 amountInWei;
	}
	/**
	 * This array stores snapshots
	 */
	Snapshot[] distributions;
	/**
	 * This variable stores a number of already distributed, but not withdrawn of wei
	 */
	uint256 reservedWei;
	/**
	 * Holds the index of last paid profit distribution to shareholder
	 * @param  {[type]} address [description]
	 * @return {[type]}         [description]
	 */
	mapping(address => uint256) lastPaidDistribution;
	/**
	 * Holds how much parts of wei cannot be paid to shareholder
	 * @param  {[type]} address [description]
	 * @return {[type]}         [description]
	 */
	mapping(address => uint256) unpaidWei;

	/**
	 * Raised when payment distribution occurs
	 */
	event Distributed(uint256 amount);
	/**
	 * Raised when shareholder withdraws his profit
	 */
	event Paid(address indexed to, uint256 amount);
	/**
	 * Raised when the contract receives Ether
	 */
	event FundsReceived(address indexed from, uint256 amount);

	function DigitalShares(uint256 _totalSupply) {
		require(_totalSupply > 0);
		require(_totalSupply <= MAX_INT256);
		totalSupply = _totalSupply;
		balances[tx.origin] = _totalSupply; // msg.sender ?
		distributions.push(Snapshot({amountInWei: 0}));
		Snapshot storage snapshot = distributions[distributions.length - 1];
		snapshot.shares[tx.origin] = int256(_totalSupply);
	}

	function transfer(address _to, uint256 _value) returns (bool) {
		if (_to == address(0)) return false;
		if (_value == 0) return false;
		if (_value > MAX_INT256) return false;

		if (super.transfer(_to, _value)) {
			Snapshot storage snapshot = distributions[distributions.length - 1];
			snapshot.shares[msg.sender] -= int256(_value);
			snapshot.shares[_to] += int256(_value);
			return true;
		}
		else {
			return false;
		}
	}

	function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
		if (_value > MAX_INT256) return false;
		if (super.transferFrom(_from, _to, _value)) {
			Snapshot storage snapshot = distributions[distributions.length - 1];
			snapshot.shares[_from] -= int256(_value);
			snapshot.shares[_to] += int256(_value);
			return true;
		} else {
			return false;
		}
	}

	function distribute(uint256 _amount) external onlyOwner {
		require(_amount > 0);

		if (_amount <= this.balance.sub(reservedWei)) {
			Snapshot storage snapshot = distributions[distributions.length - 1];
			snapshot.amountInWei = _amount;
			distributions.push(Snapshot({ amountInWei: 0}));
			reservedWei = reservedWei.add(_amount);
			Distributed(_amount);
		}
	}

	function getFreeBalance() constant returns (uint256) {
	    return this.balance.sub(reservedWei);
	}

	/**
	 * Withdraw all
	 */
	function withdraw() external returns (bool) {
		return performWithdraw(distributions.length - 1);
	}
	/**
	 * This function withdraws ether up to 'snapshotIndex' snapshot.
	 * There can be many distributions and we need to save payout at each snapshot, so we can run out of gas. So this function is needed to partially withdraw funds.
	 */
	function withdrawUpTo(uint256 _upToDistribution) external returns (bool) {
		require(_upToDistribution <= distributions.length - 1);
		return performWithdraw(_upToDistribution);
	}

	function performWithdraw(uint256 _upToDistribution) internal returns (bool) {
		uint256 numerator = unpaidWei[msg.sender];
		int256 shares = 0;
		for (uint256 i = lastPaidDistribution[msg.sender]; i < _upToDistribution; i++) {
			Snapshot storage snapshot = distributions[i];
			shares += snapshot.shares[msg.sender];
			assert(shares >= 0);
			numerator = numerator.add(snapshot.amountInWei.mul(uint256(shares)));
		}
		lastPaidDistribution[msg.sender] = _upToDistribution;
		distributions[_upToDistribution].shares[msg.sender] += shares;

		if (numerator > 0) {
			uint256 amount = numerator / totalSupply;
			unpaidWei[msg.sender] = numerator % totalSupply;
			reservedWei = reservedWei.sub(amount);

		    if (msg.sender.send(amount)) {
		    	Paid(msg.sender, amount);
		    	return true;
		    } else {
		    	revert();
		    }
		}
		return false;
	}

	function getDividends() constant returns (uint256) {
		uint256 numerator = unpaidWei[msg.sender];
		int256 shares = 0;
		for (uint256 i = lastPaidDistribution[msg.sender]; i < distributions.length - 1; i++) {
			Snapshot storage snapshot = distributions[i];
			shares += snapshot.shares[msg.sender];
			assert(shares >= 0);
			numerator = numerator.add(snapshot.amountInWei.mul(uint256(shares)));
		}
		return numerator / totalSupply;
	}

	function getDistributionCount() constant returns (uint256) {
		return distributions.length;
	}

	function getLastPaidDistribution() constant returns (uint256) {
		return lastPaidDistribution[msg.sender];
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}
