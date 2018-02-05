pragma solidity 0.4.15;

import "zeppelin/Ownable.sol";
import "zeppelin/SafeMath.sol";
import "zeppelin/StandardToken.sol";

contract DigitalSecurities is Ownable, StandardToken {
	using SafeMath for uint256;

	struct Account {
		uint256 lastDividends;
		uint256 remainder;
		uint256 fixedBalance;
	}

	mapping(address => Account) accounts;

	uint256 totalDividends;

	uint256 reserved;

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

	function DigitalSecurities(uint256 _totalSupply) {
		totalSupply = _totalSupply;
		balances[msg.sender] = _totalSupply;
	}

	modifier fixBalance(address _owner) {
		Account storage account = accounts[_owner];
		uint256 diff = totalDividends.sub(account.lastDividends);
		if (diff > 0) {
			uint256 balance = balances[_owner];

			uint256 numerator = account.remainder.add(balances[_owner].mul(diff));

			account.fixedBalance = account.fixedBalance.add(numerator.div(totalSupply));
			account.remainder = numerator % totalSupply;
			account.lastDividends = totalDividends;
		}
		_;
	}

	function muldiv(uint256 a, uint256 b, uint256 c) constant returns (uint256, uint256) {
		if (a == 0 || b == 0) return (0, 0);
		assert(c != 0);
		if (b == c) return (a, 0);
		uint256 y = b;
		uint256 r = a * b;
		uint256 n = 1;
		while (r / a != y) {
			y = y >> 1;
			r = a * y;
			n++;
		}
		uint256 sum = (r / c) * n;
		uint256 remainder = (r % c) * n;
		sum = sum + (remainder / c);
		remainder = remainder % c;
		return (sum, remainder);
	}

	function getDividends(address _owner) constant returns (uint256) {
		Account storage account = accounts[_owner];
		uint256 diff = totalDividends.sub(account.lastDividends);
		if (diff > 0) {
			uint256 numerator = account.remainder.add(balances[_owner].mul(diff));
			return account.fixedBalance.add(numerator.div(totalSupply));
		} else {
			return 0;
		}
	}

	function withdraw() fixBalance(msg.sender) external returns (bool)  {
		var amount = accounts[msg.sender].fixedBalance;
		reserved = reserved.sub(amount);
		accounts[msg.sender].fixedBalance = 0;
	    if (msg.sender.send(amount)) {
	    	Paid(msg.sender, amount);
	    	return true;
	    } else {
	    	revert();
	    }
	}

	function distribute(uint256 _amount) external onlyOwner {
		require(_amount > 0);
		if (_amount <= this.balance.sub(reserved)) {
			totalDividends = totalDividends.add(_amount);
			reserved = reserved.add(_amount);
			Distributed(_amount);
		}
	}

	function transfer(address _to, uint256 _value) fixBalance(msg.sender) fixBalance(_to) returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) fixBalance(_from) fixBalance(_to) returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function() payable {
		if (msg.value > 0) {
			FundsReceived(msg.sender, msg.value);
		}
	}
}