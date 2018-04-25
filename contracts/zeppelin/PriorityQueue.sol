pragma solidity 0.4.23;


contract PriorityQueue {

    uint8 public constant BASE = 8;

    uint256[] public items;
    mapping(uint256 => uint256) public dataStore;

    event Log(string message, uint256 logData);

    function PriorityQueue() public {
    }

    function min() public view returns (uint256) {
        if (items.length == 0) return 0;
        return dataStore[items[0]];
    }

    function size() public view returns (uint256) {
        return items.length;
    }

    function push(uint256 key, uint256 data) public {
        dataStore[key] = data;
        uint8 heapBase = BASE;
        assembly {
            let currentIdx := sload(items_slot) // currentIdx = items.length
            sstore(items_slot, add(currentIdx, 1)) // items.length++

            mstore(0x0, items_slot)
            let arrStart := keccak256(0, 32)
            let parentIdx := currentIdx

            for {} gt(currentIdx, 0) {} { // while (currentIdx > 0)
                parentIdx := div(sub(parentIdx, 1), heapBase) // parentIdx = (parentIdx - 1) / base

                let parent := sload(add(arrStart, parentIdx)) // parent = items[parentIdx]
                switch gt(parent, key) // if parent > key
                case 1 {
                    sstore(add(arrStart, currentIdx), parent) // items[currentIdx] = parent
                    currentIdx := parentIdx
                }
                default { // else
                    sstore(add(arrStart, currentIdx), key) // items[currentIdx] = key
                    return (0, 0) // return;
                }
            }
            sstore(add(arrStart, currentIdx), key) // items[currentIdx] = key
        }
    }

    function takeMin() public returns (uint256) {
        if (items.length == 0) return 0;
        uint8 heapBase = BASE;

        uint256 arrStart;
        uint256 key;
        assembly {
            mstore(0x0, items_slot)
            arrStart := keccak256(0, 32)
            key := sload(arrStart) // key = items[0]
        }
        uint256 data = dataStore[key];
        dataStore[key] = 0;

        uint256 itemCount;
        uint256 current;
        assembly {
            itemCount := sub(sload(items_slot), 1) // itemCount = items.length - 1
            current := sload(add(arrStart, itemCount)) // current = items[itemCount]
            sstore(add(arrStart, itemCount), 0) // items[itemCount] = 0
            sstore(items_slot, itemCount) // items.length = itemCount
        }

        if (itemCount == 0) return data;

        uint256 currentIdx = 0;
        uint256 smallestIdx = 0;
        uint256 smallest = current;
        uint256 child;
        uint256 idx;
        uint256 idxBase;
        uint8 i;

        while (true) {
            idxBase = heapBase * currentIdx;
            for (i = 1; i <= heapBase; i++) {
                idx = idxBase + i;
                if (idx < itemCount) {
                    assembly {
                        child := sload(add(arrStart, idx))
                    }
                    if (smallest > child) {
                        smallestIdx = idx;
                        smallest = child;
                    }
                } else {
                    break;
                }
            }
            if (smallestIdx == currentIdx) break;
            assembly {
                sstore(add(arrStart, currentIdx), smallest) // items[currentIdx] = smallest
            }
            currentIdx = smallestIdx;
            smallest = current;
        }
        assembly {
            sstore(add(arrStart, currentIdx), current) // items[currentIdx] = current
        }
        return data;
    }

    function log(string message, uint256 logData) internal {
        emit Log(message, logData);
    }
}
