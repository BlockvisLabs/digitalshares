pragma solidity 0.4.23;

import "../contracts/DigitalSecuritiesToken.sol";

contract TestDigitalSecurities is DigitalSecuritiesToken {
	constructor(uint256 _totalShares) public DigitalSecuritiesToken(_totalShares) {
	}

	function getReserved() public view returns (uint256) {
		return reserved;
	}

	function getUnpaidWei(address holder) public view returns (uint256) {
		return accounts[holder].remainder;
	}
}
