pragma solidity 0.4.23;


contract PriorityQueue {
    struct Node {
        uint256 data;
        uint64 priority;
        uint64 parent;
        uint64 left;
        uint64 right;
    }

    mapping(uint64 => Node) public items;

    uint256 public size;
    uint64 public min;
    uint64 public nextId = 1;

    function push(uint256 data, uint64 priority) public {
        size++;
        min = merge(min, makeHeap(data, priority));
    }

    function pop() public returns (uint256) {
        size--;
        uint256 data = items[min].data;
        min = takeMin(min);
        return data;
    }

    function compare(uint64 x, uint64 y) internal view returns (int8) {
        if (x == 0) return -1;
        else if (y == 0) return 1;
        else if (items[x].priority > items[y].priority) return 1;
        else if (items[x].priority < items[y].priority) return -1;
        return 0;
    }

    function link(uint64 a, uint64 b) internal returns (uint64) {
        uint64 al = items[a].left;
        items[b].right = al;
        items[al].parent = b;
        items[b].parent = a;
        items[a].left = b;
        items[a].right = 0;
        return a;
    }

    function merge(uint64 a, uint64 b) internal returns (uint64) {
        if (a == 0) return b;
        else if (b == 0) return a;
        else if (compare(a, b) < 0) return link(a, b);
        return link(b, a);
    }

    function takeMin(uint64 root) internal returns (uint64) {
        uint64 p = items[root].left;
        items[root].left = 0;
        root = p;
        while (true) {
            uint64 q = items[root].right;
            if (q == 0) break;

            p = root;
            uint64 r = items[q].right;
            uint64 s = merge(p, q);
            root = s;
            while (true) {
                p = r;
                q = items[r].right;
                if (q == 0) break;
                r = items[q].right;
                s = items[s].right = merge(p, q);
            }
            items[s].right = 0;
            if (p > 0) {
                items[p].right = root;
                root = p;
            }
        }
        items[root].parent = 0;
        return root;
    }

    function makeHeap(uint256 data, uint64 priority) internal returns (uint64) {
        uint64 id = nextId;
        items[id] = Node(data, priority, 0, 0, 0);
        nextId++;
        return id;
    }
}
