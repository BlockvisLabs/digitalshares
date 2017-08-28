pragma solidity 0.4.15;

contract TestP {
	struct DataItem {
		mapping(address => uint256) value;
	}

	DataItem[] items;

	mapping (address => uint) otherValue;

	uint counter;

	function setValue(uint256 _value) {
		items.push(DataItem());
		items[items.length - 1].value[msg.sender] = _value;
	}

	function reset() returns (uint) {
		uint result = 0;
		for (uint i = 0; i < items.length; i++) {
			mapping(address => uint) storeItem = items[i].value;
			result += storeItem[msg.sender];
			//counter = i * 10;
			storeItem[msg.sender] = 0;
		}
		return result;
	}

	function setAll() returns (uint) {
		uint result = 0;
		for (uint i = 0; i < items.length; i++) {
			mapping(address => uint) storeItem = items[i].value;
			result += storeItem[msg.sender];
			//counter = i * 10;
			storeItem[msg.sender] = 2;
		}
		return result;
	}


	function traverse() returns (uint) {
		uint result = 0;
		for(uint i = 0; i < items.length; i++) {
			mapping(address => uint) storeItem = items[i].value;
			//counter = i * 10;
			result += storeItem[msg.sender];
		}
		return result;
	}

	function rewrite(uint _value) {
		counter = _value;
	}

	function setOtherValue(uint256 _value) {
		otherValue[msg.sender] = _value;
	}
}