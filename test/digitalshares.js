var DigitalShares = artifacts.require("./DigitalShares.sol");

contract('DigitalShares', async function(accounts) {
	var contract;
	var accountOne = accounts[0];
	var accountTwo = accounts[1];

	beforeEach(async function() {
		contract = await DigitalShares.new(10000);
		await contract.send(web3.toWei(10, 'ether'));
	});

	it('should successfully create contract', async function() {
		var shares = await contract.getShares.call();
		var snapshotCount = await contract.getSnapshotCount.call();

		assert.equal(shares.toNumber(), 10000, 'account should have 10000 shares');
		assert.equal(snapshotCount, 1, 'must be 1 snapshot after initialize');
	});

	it('should successfully send shares', async function() {
		var tx = await contract.transferShares(accountTwo, 1000, {from: accountOne});

		var accountOneBalance = await contract.getShares.call();
		var accountTwoBalance = await contract.getShares.call({from: accountTwo});
		assert.equal(accountOneBalance.toNumber(), 9000, 'Owner should have 9000 shares');
		assert.equal(accountTwoBalance.toNumber(), 1000, 'Account should have 1000 shares');
	});

	it('should distribute dividends', async function() {
		await contract.transferShares(accountTwo, 1000, {from: accountOne});
		await contract.distribute(web3.toWei(10, 'ether'), {from: accountOne});
		var accountOneAmount = await contract.getDividends.call();
		var accountTwoAmount = await contract.getDividends.call({from: accountTwo});

		assert.equal(web3.fromWei(accountOneAmount.toNumber(), 'ether'), 9, 'should receive 9 ether according to shares');
		assert.equal(web3.fromWei(accountTwoAmount.toNumber(), 'ether'), 1, 'should receive 1 ether according to shares');
	});

	it('transfer -> no distribute', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});

		var balanceBefore = await contract.getDividends.call({from: accountOne});
		assert.equal(balanceBefore.toNumber(), 0, 'should be no dividends before distribution');
	});

	it('transfer -> distribute', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		var balanceBeforeOne = await contract.getDividends.call({from: accountOne});
		var balanceBeforeTwo = await contract.getDividends.call({from: accountTwo});
		await contract.distribute(web3.toWei(1, 'ether'), {from: accountOne});

		var balanceAfterOne = await contract.getDividends.call({from: accountOne});
		var balanceAfterTwo = await contract.getDividends.call({from: accountTwo});
		assert.equal(web3.fromWei(balanceAfterOne.toNumber() - balanceBeforeOne.toNumber(), 'ether'), 0.5, 'should distribute equally');
		assert.equal(web3.fromWei(balanceAfterTwo.toNumber() - balanceBeforeTwo.toNumber(), 'ether'), 0.5, 'should distribute equally');
	});

	it('transfer -> distribute -> distribute', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		var balanceBeforeOne = await contract.getDividends.call({from: accountOne});
		var balanceBeforeTwo = await contract.getDividends.call({from: accountTwo});
		await contract.distribute(web3.toWei(1, 'ether'), {from: accountOne});
		await contract.distribute(web3.toWei(1, 'ether'), {from: accountOne});

		var balanceAfterOne = await contract.getDividends.call({from: accountOne});
		var balanceAfterTwo = await contract.getDividends.call({from: accountTwo});
		assert.equal(web3.fromWei(balanceAfterOne.toNumber() - balanceBeforeOne.toNumber(), 'ether'), 1, 'should distribute equally');
		assert.equal(web3.fromWei(balanceAfterTwo.toNumber() - balanceBeforeTwo.toNumber(), 'ether'), 1, 'should distribute equally');
	});

	it('withdraw', async function() {
		var accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		var tx = await contract.withdraw({from: accountTwo});

		var accountTwoBalanceAfter = await web3.eth.getBalance(accountTwo);
		assert.isBelow(accountTwoBalanceAfter.toNumber(), accountTwoBalanceBefore.toNumber(), 'after balance must be lower than before');
	});

	it('transfer -> withdraw', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		var accountOneBalanceBefore = await web3.eth.getBalance(accountOne);
		var tx = await contract.withdraw({from: accountOne});

		var accountOneBalanceAfter = await web3.eth.getBalance(accountOne);
		assert.isBelow(accountOneBalanceAfter.toNumber(), accountOneBalanceBefore.toNumber(), 'after balance must be lower than before');
	});

	it('transfer -> distribute -> withdraw', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		var accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(web3.toWei(1, 'ether'));
		var tx = await contract.withdraw({from: accountTwo});

		var accountTwoBalanceAfter = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After: ' + web3.fromWei(accountTwoBalanceAfter.toNumber(), 'ether'));
		assert.isAbove(accountTwoBalanceAfter.toNumber(), accountTwoBalanceBefore.toNumber(), 'after balance must be higher than before');
	});

	it('transfer -> distribute -> distribute -> withdraw', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		var accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(web3.toWei(1, 'ether'));
		await contract.distribute(web3.toWei(1, 'ether'));
		var tx = await contract.withdraw({from: accountTwo});

		var accountTwoBalanceAfter = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After: ' + web3.fromWei(accountTwoBalanceAfter.toNumber(), 'ether'));
		assert.isAbove(accountTwoBalanceAfter.toNumber(), accountTwoBalanceBefore.toNumber(), 'after balance must be higher than before');
	});

	it('transfer -> distribute -> withdraw -> withdraw', async function() {
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		var accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(web3.toWei(1, 'ether'));
		var tx = await contract.withdraw({from: accountTwo});

		var accountTwoBalanceAfter1 = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After 1: ' + web3.fromWei(accountTwoBalanceAfter1.toNumber(), 'ether'));
		var tx = await contract.withdraw({from: accountTwo});

		var accountTwoBalanceAfter2 = await web3.eth.getBalance(accountTwo);
		console.log('After 2: ' + web3.fromWei(accountTwoBalanceAfter2.toNumber(), 'ether'));
		assert.isAbove(accountTwoBalanceAfter1.toNumber(), accountTwoBalanceAfter2.toNumber(), 'after 1 withdraw balance must be higher than after 2 withdraw');
	});

	it('transfer -> distribute -> transfer -> distribute', async function() {
		var accountThree = accounts[2];
		await contract.transferShares(accountTwo, 5000, {from: accountOne});
		await contract.distribute(web3.toWei(1, 'ether'));
		await contract.transferShares(accountThree, 5000, {from: accountTwo});
		await contract.distribute(web3.toWei(1, 'ether'));

		var accountOneBalance = await contract.getDividends.call({ from: accountOne });
		var accountTwoBalance = await contract.getDividends.call({ from: accountTwo });
		var accountThreeBalance = await contract.getDividends.call({ from: accountThree });
		assert.equal(web3.fromWei(accountOneBalance.toNumber(), 'ether'), 1, 'first account must have 1 ether dividends');
		assert.equal(web3.fromWei(accountTwoBalance.toNumber(), 'ether'), 0.5, 'first account must have 0.5 ether dividends');
		assert.equal(web3.fromWei(accountThreeBalance.toNumber(), 'ether'), 0.5, 'first account must have 0.5 ether dividends');
	});
});

contract('DigitalShares small', async function(accounts) {
	var contract;
	var accountOne 		= accounts[0];
	var accountTwo 		= accounts[1];
	var accountThree 	= accounts[2];

	beforeEach(async function() {
		contract = await DigitalShares.new(10);
		await contract.send(10);
	});

	it('transfer -> distribute', async function() {
		await contract.transferShares(accountTwo, 	3, {from: accountOne});
		await contract.transferShares(accountThree, 2, {from: accountOne});
		for (var i = 0; i < 5; i++) {
			await contract.distribute(1);
		}

		/**
		 * share distribution:
		 * accountOne: 		5
		 * accountTwo: 		3
		 * accountThree: 	2
		 *
		 * dividend distribution:
		 * accountOne: 		(5 * 5) / 10 = 2, 0.5 wei left
		 * accountTwo: 		(3 * 5) / 10 = 1, 0.5 wei left
		 * accountThree: 	(2 * 5) / 10 = 1, 0 wei left
		 */
		var accountOneBalance = await contract.getDividends.call({ from: accountOne });
		var accountTwoBalance = await contract.getDividends.call({ from: accountTwo });
		var accountThreeBalance = await contract.getDividends.call({ from: accountThree });
		assert.equal(accountOneBalance.toNumber(), 2, 'first account must have 2 wei dividends');
		assert.equal(accountTwoBalance.toNumber(), 1, 'first account must have 1 wei dividends');
		assert.equal(accountThreeBalance.toNumber(), 1, 'first account must have 1 wei dividends');
	});

	it('transfer -> distribute -> withdraw -> distribute -> withdraw', async function() {
		await contract.transferShares(accountTwo, 	3, {from: accountOne});
		await contract.transferShares(accountThree, 2, {from: accountOne});
		for (var i = 0; i < 5; i++) {
			await contract.distribute(1);
		}
		/**
		 * same share and dividend distribution as above
		 */
		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		assert.equal(contractBalance.toNumber(), 6, 'contract should have 6 wei left');

		for (var i = 0; i < 5; i++) {
			await contract.distribute(1);
		}

		/**
		 * dividend distribution:
		 * accountOne: 0.5 wei + (5 * 5) / 10 = 3, 0 wei left
		 * accountTwo: 0.5 wei + (3 * 5) / 10 = 2, 0 wei left
		 * accountThree: 0 wei + (2 * 5) / 10 = 1, 0 wei left
		 */

		var accountOneBalance = await contract.getDividends.call({ from: accountOne });
		var accountTwoBalance = await contract.getDividends.call({ from: accountTwo });
		var accountThreeBalance = await contract.getDividends.call({ from: accountThree });

		assert.equal(accountOneBalance.toNumber(), 3, 'first account must have 3 wei dividends');
		assert.equal(accountTwoBalance.toNumber(), 2, 'first account must have 2 wei dividends');
		assert.equal(accountThreeBalance.toNumber(), 1, 'first account must have 1 wei dividends');

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		assert.equal(contractBalance.toNumber(), 0, 'contract should have no wei left');
	});
});
