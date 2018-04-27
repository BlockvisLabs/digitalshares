pragma solidity 0.4.23;

import "../contracts/Exchange.sol";

contract TestExchange is Exchange {


    function getBestBid(address token) public view returns (uint256) {
        return pairs[token].bids.min();
    }

    function getBestAsk(address token) public view returns (uint256) {
        return pairs[token].asks.min();
    }

    function getBidQueueSize(address token) public view returns (uint256) {
        return pairs[token].bids.size();
    }

    function getAskQueueSize(address token) public view returns (uint256) {
        return pairs[token].asks.size();
    }
}
