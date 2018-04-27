pragma solidity 0.4.23;

import "./PriorityQueue.sol";
import "./DigitalSecuritiesExchangeToken.sol";
import "./zeppelin/contracts/math/SafeMath.sol";

contract Exchange {
    using SafeMath for uint256;

    struct Balance {
        uint256 available;
        uint256 reserved;
    }

    struct Pair {
        PriorityQueue asks;
        PriorityQueue bids;
        mapping (uint256 => uint256) list;
        mapping (uint256 => uint256) lastIndex;
        address token;
    }

    // this struct is 93 bytes length occupies 3 slots (32 x 3 = 96) and have 3 bytes free
    struct Order {
        uint256 amount;     // 32 bytes
        uint256 price;      // 32 bytes
        address owner;      // 20 bytes
        uint64 timestamp;   // 8 bytes
        bool sell;          // 1 byte
    }

    mapping (address => Pair) public pairs;
    mapping (uint256 => Order) public orders;

    uint256 public lastOrderId;

    mapping (address => mapping (address => Balance)) private balances;

    event Deposit(address indexed token, address indexed owner, uint amount);
    event Withdraw(address indexed token, address indexed owner, uint amount);
    event NewOrder(address indexed token, address indexed owner, uint256 id, bool sell, uint256 price, uint256 amount, uint64 timestamp);
    event NewAsk(address indexed token, uint256 price);
    event NewBid(address indexed token, uint256 price);
    event NewTrade(address indexed token, uint256 indexed bidId, uint256 indexed askId, bool side, uint256 amount, uint256 price, uint timestamp);

    /* function deposit() public payable {
        balances[0][msg.sender] = balances[0][msg.sender].add(msg.value);
        emit Deposit(0, msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        balances[0][msg.sender] = balances[0][msg.sender].sub(amount);
        msg.sender.transfer(amount);
        emit Withdraw(0, msg.sender, amount);
    }

    function depositToken(address _token, uint256 _amount) public {
        _token.transferFrom(msg.sender, this, _amount);
        balances[_token][msg.sender].available = balances[_token][msg.sender].available.add(_amount);
        Deposit(0, msg.sender, msg.value);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        balances[_token][msg.sender].available = balances[_token][msg.sender].available.sub(_amount);
        _token.transfer(msg.sender, _amount);
        Withdraw(_token, msg.sender, _amount);
    } */

    function addPair(address _token) public {
        pairs[_token].asks = new PriorityQueue();
        pairs[_token].bids = new PriorityQueue();
    }

    function sell(address _token, uint256 _amount, uint256 _price) public returns (uint256) {
        require(_amount > 0);
        require(_price > 0);
        require(pairs[_token].asks != address(0));

        Order memory order = Order(
            _amount,
            _price,
            msg.sender,
            getNow(),
            true
        );

        uint256 orderId = ++lastOrderId;
        emit NewOrder(_token, msg.sender, orderId, true, order.price, order.amount, order.timestamp);

        Pair storage pair = pairs[_token];

        uint256 bestBid = pair.bids.min();
        if (bestBid > 0) {
            Order storage buyOrder = orders[bestBid];
            if (buyOrder.price >= order.price) {
                uint256 tradeAmount = 0;
                uint256 tradePrice = order.price;
                if (buyOrder.amount >= order.amount) {
                    buyOrder.amount = buyOrder.amount.sub(order.amount);
                    tradeAmount = order.amount;
                    order.amount = 0;
                } else {
                    order.amount = order.amount.sub(buyOrder.amount);
                    tradeAmount = buyOrder.amount;
                    buyOrder.amount = 0;
                    emit NewAsk(_token, _price);
                    pair.asks.push(_price, orderId);
                }
                if (buyOrder.amount == 0) {
                    pair.bids.takeMin();
                }
                emit NewTrade(_token, bestBid, orderId, true, tradeAmount, tradePrice, order.timestamp);
            } else {
                emit NewAsk(_token, _price);
                pair.asks.push(_price, orderId);
            }
        } else {
            emit NewAsk(_token, _price);
            pair.asks.push(_price, orderId);
        }
        orders[orderId] = order;
        return orderId;
    }

    function buy(address _token, uint256 _amount, uint256 _price) public returns (uint256) {
        require(_amount > 0);
        require(_price > 0);
        require(pairs[_token].bids != address(0));

        Order memory order = Order(
            _amount,
            _price,
            msg.sender,
            getNow(),
            false
        );

        uint256 orderId = ++lastOrderId;
        emit NewOrder(_token, msg.sender, orderId, false, order.price, order.amount, order.timestamp);
        pairs[_token].bids.push((~uint256(0)).sub(_price), orderId);

        orders[orderId] = order;
        return orderId;
    }

    /* function sell(address _token, uint256 _amount, uint256 _price) public returns (uint256) {
        require(_amount > 0);
        require(_price > 0);
        DigitalSecuritiesExchangeToken token = DigitalSecuritiesExchangeToken(_token);

        uint256 exchangeBalance = token.exchangeAllowance(msg.sender, address(this));
        require(exchangeBalance >= _amount);

        Order memory order;
        order.sell = true;
        order.owner = msg.sender;
        order.price = price;
        order.amount = amount;
        order.timestamp = uint64(now);

        uint64 id = ++lastOrderId;
        emit Order(token, msg.sender, id, true, price, amount, order.timestamp);

        Pair storage pair = pairs[token];
        matchSell(token, pair, order, id);

        if (order.amount != 0) {
            uint64 currentOrderId;
            uint64 n = pair.pricesTree.find(price);
            if (n != 0 && price >= orders[n].price) {
                currentOrderId = pair.orderbook[n].next;
            } else {
                currentOrderId = n;
            }

            ListItem memory orderItem;
            orderItem.next = currentOrderId;
            uint64 prevOrderId;
            if (currentOrderId != 0) {
                prevOrderId = pair.orderbook[currentOrderId].prev;
                pair.orderbook[currentOrderId].prev = id;
            } else {
                prevOrderId = pair.lastOrder;
                pair.lastOrder = id;
            }

            orderItem.prev = prevOrderId;
            if (prevOrderId != 0) {
                pair.orderbook[prevOrderId].next = id;
            } else {
                pair.firstOrder = id;
            }

            if (currentOrderId == pair.bestAsk) {
                pair.bestAsk = id;
                Ask(token, order.price);
            }

            orders[id] = order;
            pair.orderbook[id] = orderItem;
            pair.pricesTree.placeAfter(n, id, price);
        }

        return id;
    }

    function matchSell(address token, Pair storage pair, Order order, uint64 id) private {
        uint64 currentOrderId = pair.bestBid;
        while (currentOrderId != 0 && order.amount != 0 && order.price <= orders[currentOrderId].price) {
            Order memory matchingOrder = orders[currentOrderId];
            uint tradeAmount;
            if (matchingOrder.amount >= order.amount) {
                tradeAmount = order.amount;
                matchingOrder.amount -= order.amount;
                order.amount = 0;
            } else {
                tradeAmount = matchingOrder.amount;
                order.amount -= matchingOrder.amount;
                matchingOrder.amount = 0;
            }

            balances[token][msg.sender].reserved = balances[token][msg.sender].reserved.sub(tradeAmount);
            balances[token][matchingOrder.owner].available = balances[token][matchingOrder.owner].available.add(tradeAmount);
            balances[0][matchingOrder.owner].reserved = balances[0][matchingOrder.owner].reserved.sub(tradeAmount.mul(matchingOrder.price));
            balances[0][msg.sender].available = balances[0][msg.sender].available.add(tradeAmount.mul(matchingOrder.price));

            Trade(token, currentOrderId, id, false, tradeAmount, matchingOrder.price, uint64(now));

            if (matchingOrder.amount != 0) {
                orders[currentOrderId] = matchingOrder;
                break;
            }

            ListItem memory item = excludeItem(pair, currentOrderId);
            currentOrderId = item.prev;
        }

        if (pair.bestBid != currentOrderId) {
            pair.bestBid = currentOrderId;
            Bid(token, orders[currentOrderId].price);
        }
    }

    function buy(address token, uint amount, uint price) public returns (uint64) {
        balances[0][msg.sender].available = balances[0][msg.sender].available.sub(amount.mul(price));
        balances[0][msg.sender].reserved = balances[0][msg.sender].reserved.add(amount.mul(price));

        Order memory order;
        order.sell = false;
        order.owner = msg.sender;
        order.price = price;
        order.amount = amount;
        order.timestamp = uint64(getNow());

        uint64 id = ++lastOrderId;
        Order(token, msg.sender, id, false, price, amount, order.timestamp);

        Pair storage pair = pairs[token];
        matchBuy(token, pair, order, id);

        if (order.amount != 0) {
            uint64 currentOrderId;
            uint64 n = pair.pricesTree.find(price);
            if (n != 0 && price <= orders[n].price) {
                currentOrderId = pair.orderbook[n].prev;
            } else {
                currentOrderId = n;
            }

            ListItem memory orderItem;
            orderItem.prev = currentOrderId;
            uint64 prevOrderId;
            if (currentOrderId != 0) {
                prevOrderId = pair.orderbook[currentOrderId].next;
                pair.orderbook[currentOrderId].next = id;
            } else {
                prevOrderId = pair.firstOrder;
                pair.firstOrder = id;
            }

            orderItem.next = prevOrderId;
            if (prevOrderId != 0) {
                pair.orderbook[prevOrderId].prev = id;
            } else {
                pair.lastOrder = id;
            }

            if (currentOrderId == pair.bestBid) {
                pair.bestBid = id;
                Bid(token, order.price);
            }

            orders[id] = order;
            pair.orderbook[id] = orderItem;
            pair.pricesTree.placeAfter(n, id, order.price);
        }

        return id;
    }

    function matchBuy(address token, Pair storage pair, Order order, uint64 id) private {
        uint64 currentOrderId = pair.bestAsk;
        while (currentOrderId != 0 && order.amount > 0 && order.price >= orders[currentOrderId].price) {
            Order memory matchingOrder = orders[currentOrderId];
            uint tradeAmount;
            if (matchingOrder.amount >= order.amount) {
                tradeAmount = order.amount;
                matchingOrder.amount -= order.amount;
                order.amount = 0;
            } else {
                tradeAmount = matchingOrder.amount;
                order.amount -= matchingOrder.amount;
                matchingOrder.amount = 0;
            }

            balances[0][order.owner].reserved = balances[0][order.owner].reserved.sub(tradeAmount.mul(order.price));
            balances[0][order.owner].available = balances[0][order.owner].available.add(tradeAmount.mul(order.price - matchingOrder.price));
            balances[token][matchingOrder.owner].reserved = balances[token][matchingOrder.owner].reserved.sub(tradeAmount);
            balances[0][matchingOrder.owner].available = balances[0][matchingOrder.owner].available.add(tradeAmount.mul(matchingOrder.price));
            balances[token][order.owner].available = balances[token][order.owner].available.add(tradeAmount);

            Trade(token, id, currentOrderId, true, tradeAmount, matchingOrder.price, uint64(now));

            if (matchingOrder.amount != 0) {
                orders[currentOrderId] = matchingOrder;
                break;
            }

            ListItem memory item = excludeItem(pair, currentOrderId);
            currentOrderId = item.next;
        }

        if (pair.bestAsk != currentOrderId) {
            pair.bestAsk = currentOrderId;
            Ask(token, orders[currentOrderId].price);
        }
    }

    function cancelOrder(address token, uint64 id) isToken(token) public {
        Order memory order = orders[id];
        require(order.owner == msg.sender);

        if (order.sell) {
            balances[token][msg.sender].reserved = balances[token][msg.sender].reserved.sub(order.amount);
            balances[token][msg.sender].available = balances[token][msg.sender].available.add(order.amount);
        } else {
            balances[0][msg.sender].reserved = balances[0][msg.sender].reserved.sub(order.amount.mul(order.price));
            balances[0][msg.sender].available = balances[0][msg.sender].available.add(order.amount.mul(order.price));
        }

        Pair storage pair = pairs[token];
        ListItem memory orderItem = excludeItem(pair, id);

        if (pair.bestBid == id) {
            pair.bestBid = orderItem.prev;
            Bid(token, orders[pair.bestBid].price);
        } else if (pair.bestAsk == id) {
            pair.bestAsk = orderItem.next;
            Ask(token, orders[pair.bestAsk].price);
        }
    }

    function excludeItem(Pair storage pair, uint64 id) private returns (ListItem) {
        ListItem memory matchingOrderItem = pair.orderbook[id];
        if (matchingOrderItem.next != 0) {
            pair.orderbook[matchingOrderItem.next].prev = matchingOrderItem.prev;
        }

        if (matchingOrderItem.prev != 0) {
            pair.orderbook[matchingOrderItem.prev].next = matchingOrderItem.next;
        }

        if (pair.lastOrder == id) {
            pair.lastOrder = matchingOrderItem.prev;
        }

        if (pair.firstOrder == id) {
            pair.firstOrder = matchingOrderItem.next;
        }

        pair.pricesTree.remove(id);
        delete pair.orderbook[id];
        delete orders[id];

        return matchingOrderItem;
    }

    function getBalance(address token, address trader) public constant returns (uint available, uint reserved) {
        available = balances[token][trader].available;
        reserved = balances[token][trader].reserved;
    }

    function getOrderBookInfo(address token) public constant returns (uint64 firstOrder, uint64 bestBid, uint64 bestAsk, uint64 lastOrder) {
        Pair memory pair = pairs[token];
        firstOrder = pair.firstOrder;
        bestBid = pair.bestBid;
        bestAsk = pair.bestAsk;
        lastOrder = pair.lastOrder;
    }

    function getOrder(address token, uint64 id) public constant returns (uint price, bool sell, uint amount, uint64 next, uint64 prev) {
        Order memory order = orders[id];
        price = order.price;
        sell = order.sell;
        amount = order.amount;
        next = pairs[token].orderbook[id].next;
        prev = pairs[token].orderbook[id].prev;
    } */

    function getNow() internal view returns (uint64) {
        return uint64(now);
    }

}
