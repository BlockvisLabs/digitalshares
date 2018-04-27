pragma solidity 0.4.23;


contract PriorityQueue {

    uint8 public constant BASE = 32;

    uint256[] public heap;
    mapping(uint256 => uint256) public heapMap;

    function min() public view returns (uint256) {
        if (heap.length == 0) return 0;
        return heapMap[heap[0]];
    }

    function size() public view returns (uint256) {
        return heap.length;
    }

    function push(uint256 key, uint256 value) public {
        require(heapMap[key] == 0);
        uint256 heapBase = BASE;
        heapMap[key] = value;
        assembly {
            let currentIdx := sload(heap_slot) // currentIdx = heap.length
            sstore(heap_slot, add(currentIdx, 1)) // heap.length++

            mstore(0, heap_slot)
            let heapStorageBase := keccak256(0, 32)
            let parentIdx := currentIdx

            for {} gt(currentIdx, 0) {} { // while (currentIdx > 0)
                parentIdx := div(sub(parentIdx, 1), heapBase) // parentIdx = (parentIdx - 1) / BASE

                let parent := sload(add(heapStorageBase, parentIdx)) // parent = heap[parentIdx]
                switch gt(parent, key) // if parent > key
                case 1 {
                    sstore(add(heapStorageBase, currentIdx), parent) // heap[currentIdx] = parent
                    currentIdx := parentIdx
                }
                default { // else
                    sstore(add(heapStorageBase, currentIdx), key) // heap[currentIdx] = key
                    return (0, 0) // return;
                }
            }
            sstore(add(heapStorageBase, currentIdx), key) // heap[currentIdx] = key
        }
    }

    function takeMin() public returns (uint256) {
        uint256 heapSize = heap.length;
        if (heapSize == 0) return 0;

        uint256 current;
        uint256 heapStorageBase;
        uint256 value;
        assembly {
            mstore(0, heap_slot)
            heapStorageBase := keccak256(0, 32)
            mstore(0, sload(heapStorageBase)) // key = heap[0]
            mstore(32, heapMap_slot)
            let keyStoreSlot := keccak256(0, 64)
            value := sload(keyStoreSlot) // value = heapMap[key]
            sstore(keyStoreSlot, 0) // heapMap[key] = 0
            heapSize := sub(heapSize, 1) // heapSize = heapSize - 1
            let last := add(heapStorageBase, heapSize)
            current := sload(last) // current = heap[heapSize]
            sstore(last, 0) // heap[heapSize] = 0
            sstore(heap_slot, heapSize) // heap.length = heapSize
        }

        if (heapSize == 0) return value;

        uint256 heapBase = BASE;
        uint256 currentIdx = 0;
        uint256 smallestIdx = 0;
        uint256 smallest = current;
        uint256 child;
        uint256 idx;
        uint256 idxBase;
        uint256 i;

        while (true) {
            idxBase = heapBase * currentIdx;
            for (i = 1; i <= heapBase; i++) {
                idx = idxBase + i;
                if (idx >= heapSize) break;

                assembly {
                    child := sload(add(heapStorageBase, idx))
                }
                if (smallest > child) {
                    smallestIdx = idx;
                    smallest = child;
                }
            }
            if (smallestIdx == currentIdx) break;
            assembly {
                sstore(add(heapStorageBase, currentIdx), smallest) // heap[currentIdx] = smallest
            }
            currentIdx = smallestIdx;
            smallest = current;
        }
        assembly {
            sstore(add(heapStorageBase, currentIdx), current) // heap[currentIdx] = current
        }
        return value;
    }
}
