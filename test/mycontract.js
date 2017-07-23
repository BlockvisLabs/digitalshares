var MyContract = artifacts.require("./MyContract.sol");

contract('MyContract', function(accounts) {
	it('should assign 10000 shares to owner', function() {
		var contract;
		return MyContract.deployed().then(function(instance) {
			contract = instance;
			return contract.getShares(accounts[0]);
		}).then(function(shares) {
			assert.equal(10000, shares.toNumber(), '10000 shares assigned to owner');
		});
		// var contract = await MyContract.deployed();
		// var sum = await contract.getShares();
		// assert.equal(sum.toNumber(), 10000, '10000 shares assigned to owner');
		// return sum;
	});

	it('should successful send shares', function() {
		var contract;
		var amountToSend = 1000;
		return MyContract.deployed().then(function(instance) {
			contract = instance;
			return contract.sendShares(accounts[1], amountToSend, {from: accounts[0]});
		}).then(function() {
			return contract.getShares.call();
		}).then(function(shares) {
			assert.equal(shares.toNumber(), 9000, 'Owner should have 9000 shares');
			return contract.getShares({from: accounts[1]});
		}).then(function(shares) {
			assert.equal(shares.toNumber(), 1000, 'Account should have 1000 shares');
		});
	});
});

contract('MyContract distribute', function(accounts) {
	it('should distribute dividends', function() {
		var contract;
		var amountToSend = 1000;
		return MyContract.deployed().then(function(instance) {
			contract = instance;
			return contract.sendShares(accounts[1], amountToSend, {from: accounts[0]});
		}).then(function() {
			return contract.sendTransaction({from: accounts[0], to: contract.address, value: web3.toWei(10, 'ether')});
		}).then(function() {
			return contract.distributeDividends(web3.toWei(10, 'ether'), {from: accounts[0]});
		}).then(function() {
			return contract.getDividends.call();
		}).then(function(amount) {
			assert.equal(web3.fromWei(amount.toNumber(), 'ether'), 9, 'should receive 9 ether according to shares');
			return contract.getDividends.call({from: accounts[1]});
		}).then(function(amount) {
			assert.equal(web3.fromWei(amount.toNumber(), 'ether'), 1, 'should receive 1 ether according to shares');
		});
	});
});