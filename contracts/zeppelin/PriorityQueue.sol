pragma solidity 0.4.23;


contract PriorityQueue {

    uint256[] public items;
    mapping(uint256 => uint256) public dataStore;

    function push(uint256 key, uint256 data) public {
        items.push(key);
        dataStore[key] = data;
        bubbleUp(items.length - 1);
    }

    function takeMin() public returns (uint256) {
        if (items.length == 0) return 0;
        uint256 data = dataStore[items[0]];
        uint256 last = items.length - 1;
        items[0] = items[last];
        dataStore[last] = 0;
        items[last] = 0;
        items.length--;
        bubbleDown();
        return data;
    }

    function size() public view returns (uint256) {
        return items.length;
    }

    function bubbleUp(uint256 index) internal {
        if (index == 0) return;

        uint256 current = items[index];
        uint256 parent = 0;
        uint256 parentIndex = 0;

        uint256 arrStart;
        assembly {
            arrStart := keccak256(items_slot, 32)
        }
        while (index > 0) {

            assembly {
                parentIndex := div(sub(index, 1), 2)
                parent := sload(add(arrStart, parentIndex))
            }

            if (current >= parent) break;

            assembly {
                sstore(add(arrStart, parentIndex), current)
                sstore(add(arrStart, index), parent)

            }

            index = parentIndex;
            current = parent;
        }
    }

    function bubbleDown() internal {
        uint256 itemCount = items.length;
        if (itemCount == 0) return;
        uint256 smallest = 0;
        uint256 current;
        uint256 leftIndex;
        uint256 rightIndex;
        uint256 leftValue;
        uint256 rightValue;
        uint256 arrStart;
        uint256 smallestValue = items[smallest];
        uint256 currentValue;
        assembly {
            arrStart := keccak256(items_slot, 32)
        }

        while (true) {
            current = smallest;
            currentValue = smallestValue;
            leftIndex = 2 * smallest + 1;
            rightIndex = 2 * smallest + 2;
            if (leftIndex < itemCount) {
                assembly {
                    leftValue := sload(add(arrStart, leftIndex))
                }

                if (leftValue < smallestValue) {
                    smallest = leftIndex;
                    smallestValue = leftValue;
                }
            } else if (rightIndex < itemCount) {
                assembly {
                    rightValue := sload(add(arrStart, rightIndex))
                }
                if (rightValue < smallestValue) {
                    smallest = rightIndex;
                    smallestValue = rightValue;
                }
            }

            if (smallest == current) break;

            assembly {
                sstore(add(arrStart, smallest), currentValue)
                sstore(add(arrStart, current), smallestValue)
            }
        }
    }
}
