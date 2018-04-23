pragma solidity 0.4.23;


contract PriorityQueue {

    uint256[] public items;
    mapping(uint256 => uint256) public dataStore;

    event Log(string message, uint256 logData);

    function PriorityQueue() public {
        items.push(0);
    }

    function log(string message, uint256 logData) internal {
        emit Log(message, logData);
    }

    function push(uint256 key, uint256 data) public {
        dataStore[key] = data;
        assembly {

            sstore(items_slot, add(sload(items_slot), 1)) // items.length++

            let currentIdx := sub(sload(items_slot), 1) // currentIdx = items.length - 1
            if eq(currentIdx, 0) { return (0, 0) } // if (currentIdx == 0) return;

            mstore(0x0, items_slot)
            let arrStart := keccak256(0, 32)
            let parentIdx := currentIdx

            for {} gt(currentIdx, 0) {} { // while (currentIdx > 0)
                parentIdx := div(parentIdx, 2) // parentIdx = parentIdx / 2
                let parent := sload(add(arrStart, parentIdx)) // parent = items[parentIdx]
                switch gt(parent, key) // if parent > key
                case 1 {
                    sstore(add(arrStart, currentIdx), parent) // items[currentIdx] = parent
                    currentIdx := parentIdx
                }
                default { // else
                    sstore(add(arrStart, currentIdx), key) // items[currentIdx] = key
                    return (0, 0) // break
                }
            }
            sstore(add(arrStart, currentIdx), key) // items[currentIdx] = current
        }
    }

    function takeMin() public returns (uint256) {
        if (items.length < 2) return 0;

        uint256 arrStart;
        uint256 key;
        assembly {
            mstore(0x0, items_slot)
            arrStart := keccak256(0, 32)
            key := sload(add(arrStart, 1)) // key = items[1]
        }
        uint256 data = dataStore[key];
        dataStore[key] = 0;

        uint256 last;

        assembly {
            let lastIndex := sub(sload(items_slot), 1) // lastIndex = items.length - 1
            last := sload(add(arrStart, lastIndex))
            //sstore(add(arrStart, 1), ) // items[1] = items[lastIndex]
            sstore(add(arrStart, lastIndex), 0) // items[lastIndex] = 0
            sstore(items_slot, lastIndex) // items.length = last
        }
        bubbleDown(last);
        return data;
    }

    function bubbleDown(uint256 current) internal {
        uint256 itemCount = items.length;
        uint256 arrStart;
        assembly {
            mstore(0x0, items_slot)
            arrStart := keccak256(0, 32)
        }
        uint256 currentIdx = 1;
        uint256 smallestIdx = 1;
        uint256 smallest = current;
        uint256 leftChildIdx;
        uint256 rightChildIdx;
        uint256 left;
        uint256 right;

        while (true) {
            leftChildIdx = 2 * currentIdx;
            rightChildIdx = leftChildIdx + 1;
            if (leftChildIdx < itemCount) {
                assembly {
                    left := sload(add(arrStart, leftChildIdx)) // left = items[leftChildIdx]
                }
                if (smallest > left) {
                    smallestIdx = leftChildIdx;
                    smallest = left;
                }
            }
            if (rightChildIdx < itemCount) {
                assembly {
                    right := sload(add(arrStart, rightChildIdx)) // left = items[rightChildIdx]
                }
                if (smallest > right) {
                    smallestIdx = rightChildIdx;
                    smallest = right;
                }
            }
            if (smallestIdx == currentIdx) break;

            assembly {
                sstore(add(arrStart, currentIdx), smallest) // items[currentIdx] = smallest
            }
            currentIdx = smallestIdx;
        }
        assembly {
            sstore(add(arrStart, smallestIdx), current) // items[smallestIdx] = current
        }
    }

    function min() public view returns (uint256) {
        if (items.length == 0) return 0;
        return dataStore[items[1]];
    }

    function size() public view returns (uint256) {
        return items.length - 1;
    }
}
