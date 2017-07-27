var DigitalShares = artifacts.require("./DigitalShares.sol");

contract('DigitalShares', function(accounts) {
	it('should successfully initialize', function() {
		var contract;
		return DigitalShares.deployed().then(function(instance) {
			contract = instance;
			return contract.initialize();
		}).then(function() {
			return contract.getSnapshotCount.call();
		}).then(function(snapshotCount) {
			assert.equal(snapshotCount, 1, 'must be 1 snapshot after initialize');
		});
	});

	it('should successfully add shares', function() {
		var contract;
		return DigitalShares.deployed().then(function(instance) {
			contract = instance;
			return contract.addShare(accounts[0], 10000, {from: accounts[0]});
		}).then(function() {
			return contract.getShares.call();
		}).then(function(shares) {
			assert.equal(shares, 10000, 'account should have 10000 shares');
		});
	});

	it('should successfully send shares', function() {
		var contract;
		var amountToSend = 1000;
		return DigitalShares.deployed().then(function(instance) {
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

contract('DigitalShares distribute', function(accounts) {
	it('should successfully initialize', function() {
		var contract;
		return DigitalShares.deployed().then(function(instance) {
			contract = instance;
			return contract.initialize();
		}).then(function() {
			return contract.addShare(accounts[0], 10000, {from: accounts[0]});
		});
	});
	it('should distribute dividends', function() {
		var contract;
		var amountToSend = 1000;
		return DigitalShares.deployed().then(function(instance) {
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

contract('DigitalShares massive distribute test', function(accounts) {
	it('should successfully initialize', function() {
		var contract;
		return DigitalShares.deployed().then(function(instance) {
			contract = instance;
			return contract.initialize();
		}).then(function() {
			return contract.addShare(accounts[0], 10000, {from: accounts[0]});
		});
	});
	it('should successfully send shares and distribute', function() {
		var contract;
		return DigitalShares.deployed().then(function(instance) {
			contract = instance;
			return contract.sendTransaction({ from: accounts[0], to: contract.address, value: web3.toWei(10, 'ether') });
		}).then(function() {
			var promise = new Promise(function(resolve, reject) {
				resolve();
			});
			for (var i = 1; i < accounts.length; i++) {
				(function(index) {
					promise = promise.then(function() {
						return contract.sendShares(accounts[index], 10, {from: accounts[0], gas: 4712388});
					});
				})(i);
			}
			console.log('Sending shares to ' + accounts.length + ' accounts');
			return promise;
		}).then(function(holders) {
			console.log('Distributing...');
			return contract.distributeDividends(web3.toWei(10, 'ether'), {from: accounts[0], gas: 4712388});
		}).then(function(tx) {
			console.log(tx);
		});
	});

	it('should successfully withdraw', function() {
		var contract;
		return DigitalShares.deployed().then(function(instance) {
			contract = instance;
			return contract.withdraw({from: accounts[1]});
		}).then(function(tx) {
			console.log(tx);
			return web3.eth.getBalance(accounts[1]);
		}).then(function(amount) {
			assert.isAbove(amount, 0);
		});
	});
});