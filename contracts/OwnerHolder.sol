pragma solidity ^0.4.11;
/**
 * The only purpose of this contract is to hold owner for ShareSnapshot
 */
contract OwnerHolder {
	address public owner;

	function OwnerHolder() {
		owner = msg.sender;
	}

	function setOwner(address newOwner) {
		require(newOwner != address(0));
		require(msg.sender == owner);
		owner = newOwner;
	}

}