pragma solidity 0.4.23;

import "./zeppelin/contracts/ownership/Ownable.sol";
import "./zeppelin/contracts/math/SafeMath.sol";
import "./zeppelin/contracts/token/ERC20/StandardToken.sol";


contract DigitalSecuritiesToken is Ownable, StandardToken {
    using SafeMath for uint256;

    struct Account {
        uint256 lastDividends;
        uint256 remainder;
        uint256 fixedBalance;
    }

    mapping(address => Account) public accounts;

    uint256 public totalDividends;

    uint256 public reserved;

    /**
     * Raised when payment distribution occurs
     */
    event Distributed(uint256 amount);
    /**
     * Raised when shareholder withdraws his profit
     */
    event Paid(address indexed to, uint256 amount);
    /**
     * Raised when the contract receives Ether
     */
    event FundsReceived(address indexed from, uint256 amount);

    constructor(uint256 _totalSupply) public {
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    function fixBalance(address _tokenOwner) internal {
        Account storage account = accounts[_tokenOwner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff == 0) return;

        uint256 numerator = account.remainder.add(balances[_tokenOwner].mul(diff));

        account.fixedBalance = account.fixedBalance.add(numerator.div(totalSupply_));
        account.remainder = numerator % totalSupply_;
        account.lastDividends = totalDividends;
    }

    function() public payable {
        if (msg.value > 0) {
            emit FundsReceived(msg.sender, msg.value);
        }
    }

    function withdraw() external returns (bool) {
        fixBalance(msg.sender);
        uint256 amount = accounts[msg.sender].fixedBalance;
        reserved = reserved.sub(amount);
        accounts[msg.sender].fixedBalance = 0;
        msg.sender.transfer(amount);
        emit Paid(msg.sender, amount);
        return true;
    }

    function distribute(uint256 _amount) external onlyOwner {
        require(_amount > 0);
        if (_amount > address(this).balance.sub(reserved)) revert();

        totalDividends = totalDividends.add(_amount);
        reserved = reserved.add(_amount);
        emit Distributed(_amount);
    }

    function getDividends(address _tokenOwner) public view returns (uint256) {
        Account storage account = accounts[_tokenOwner];
        uint256 diff = totalDividends.sub(account.lastDividends);
        if (diff == 0) return 0;

        uint256 numerator = account.remainder.add(balances[_tokenOwner].mul(diff));
        return account.fixedBalance.add(numerator.div(totalSupply_));
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        fixBalance(msg.sender);
        fixBalance(_to);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        fixBalance(_from);
        fixBalance(_to);
        return super.transferFrom(_from, _to, _value);
    }
}
