pragma solidity ^0.4.15;

import "../contracts/DigitalSecurities.sol";

contract TestDigitalSecurities is DigitalSecurities {
	function TestDigitalSecurities(uint256 _totalShares) DigitalSecurities(_totalShares) {
	}

	function getReserved() constant returns (uint256) {
		return reserved;
	}

	function getUnpaidWei(address holder) constant returns (uint256) {
		return accounts[holder].remainder;
	}
}