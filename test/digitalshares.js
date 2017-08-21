var TestDigitalShares = artifacts.require("../test/TestDigitalShares.sol");

contract('DigitalShares', async function(accounts) {
	var contract;
	var accountOne = accounts[0];
	var accountTwo = accounts[1];

	beforeEach(async function() {
		contract = await TestDigitalShares.new(10000);
		await contract.send(web3.toWei(10, 'ether'));
	});

	it('should successfully create contract', async function() {
		var shares = await contract.balanceOf.call(accountOne);
		var snapshotCount = await contract.getSnapshotCount.call();

		assert.equal(shares.toNumber(), 10000, 'account should have 10000 shares');
		assert.equal(snapshotCount, 1, 'must be 1 snapshot after initialize');
	});

	it('should successfully send shares', async function() {
		var tx = await contract.transfer(accountTwo, 1000, {from: accountOne});

		var accountOneBalance = await contract.balanceOf.call(accountOne);
		var accountTwoBalance = await contract.balanceOf.call(accountTwo);
		assert.equal(accountOneBalance.toNumber(), 9000, 'Owner should have 9000 shares');
		assert.equal(accountTwoBalance.toNumber(), 1000, 'Account 2 should have 1000 shares');
	});

	it('should not send more shares than actually have', async function() {
		try {
			var tx = await contract.transfer(accountTwo, 10001, {from: accountOne});
		} catch(e) {} // testrpc throws 'invalid opcode' on assert()

		var accountOneBalance = await contract.balanceOf.call(accountOne);
		var accountTwoBalance = await contract.balanceOf.call(accountTwo);
		assert.equal(accountOneBalance.toNumber(), 10000, 'Owner should have 10000 shares');
		assert.equal(accountTwoBalance.toNumber(), 0, 'Account 2 should have 0 shares');
	});

	it('should distribute dividends', async function() {
		await contract.transfer(accountTwo, 1000, {from: accountOne});
		await contract.distribute(web3.toWei(10, 'ether'), {from: accountOne});
		var accountOneAmount = await contract.getDividends.call();
		var accountTwoAmount = await contract.getDividends.call({from: accountTwo});

		assert.equal(web3.fromWei(accountOneAmount.toNumber(), 'ether'), 9, 'should receive 9 ether according to shares');
		assert.equal(web3.fromWei(accountTwoAmount.toNumber(), 'ether'), 1, 'should receive 1 ether according to shares');
	});

	it('should fail to distribute more dividends than have ether on balance', async function() {
		await contract.distribute(web3.toWei(10, 'ether') + 1, {from: accountOne});
		var accountOneAmount = await contract.getDividends.call({from: accountOne});
		assert.equal(accountOneAmount.toNumber(), 0, 'should not distribute');
	});

	it('transfer -> no distribute', async function() {
		await contract.transfer(accountTwo, 5000, {from: accountOne});

		var balanceBefore = await contract.getDividends.call({from: accountOne});
		assert.equal(balanceBefore.toNumber(), 0, 'should be no dividends before distribution');
	});

	it('transfer -> distribute', async function() {
		await contract.transfer(accountTwo, 5000, {from: accountOne});
		var balanceBeforeOne = await contract.getDividends.call({from: accountOne});
		var balanceBeforeTwo = await contract.getDividends.call({from: accountTwo});
		await contract.distribute(web3.toWei(1, 'ether'), {from: accountOne});

		var balanceAfterOne = await contract.getDividends.call({from: accountOne});
		var balanceAfterTwo = await contract.getDividends.call({from: accountTwo});
		assert.equal(web3.fromWei(balanceAfterOne.toNumber() - balanceBeforeOne.toNumber(), 'ether'), 0.5, 'should distribute equally');
		assert.equal(web3.fromWei(balanceAfterTwo.toNumber() - balanceBeforeTwo.toNumber(), 'ether'), 0.5, 'should distribute equally');
	});

	it('transfer -> distribute -> distribute', async function() {
		await contract.transfer(accountTwo, 5000, {from: accountOne});
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
		await contract.transfer(accountTwo, 5000, {from: accountOne});
		var accountOneBalanceBefore = await web3.eth.getBalance(accountOne);
		var tx = await contract.withdraw({from: accountOne});

		var accountOneBalanceAfter = await web3.eth.getBalance(accountOne);
		assert.isBelow(accountOneBalanceAfter.toNumber(), accountOneBalanceBefore.toNumber(), 'after balance must be lower than before');
	});

	it('transfer -> distribute -> withdraw', async function() {
		await contract.transfer(accountTwo, 5000, {from: accountOne});
		var accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(web3.toWei(1, 'ether'));
		var tx = await contract.withdraw({from: accountTwo});

		var accountTwoBalanceAfter = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After: ' + web3.fromWei(accountTwoBalanceAfter.toNumber(), 'ether'));
		assert.isAbove(accountTwoBalanceAfter.toNumber(), accountTwoBalanceBefore.toNumber(), 'after balance must be higher than before');
	});

	it('transfer -> distribute -> distribute -> withdraw', async function() {
		await contract.transfer(accountTwo, 5000, {from: accountOne});
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
		await contract.transfer(accountTwo, 5000, {from: accountOne});
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
		await contract.transfer(accountTwo, 5000, {from: accountOne});
		await contract.distribute(web3.toWei(1, 'ether'));
		await contract.transfer(accountThree, 5000, {from: accountTwo});
		await contract.distribute(web3.toWei(1, 'ether'));

		var accountOneBalance = await contract.getDividends.call({ from: accountOne });
		var accountTwoBalance = await contract.getDividends.call({ from: accountTwo });
		var accountThreeBalance = await contract.getDividends.call({ from: accountThree });
		assert.equal(web3.fromWei(accountOneBalance.toNumber(), 'ether'), 1, 'first account must have 1 ether dividends');
		assert.equal(web3.fromWei(accountTwoBalance.toNumber(), 'ether'), 0.5, 'second account must have 0.5 ether dividends');
		assert.equal(web3.fromWei(accountThreeBalance.toNumber(), 'ether'), 0.5, 'third account must have 0.5 ether dividends');
	});

	it('after distribute->transfer cycle snapshot must hold data ', async function() {
		for (var i = 0; i < 3; i++) {
			await contract.distribute(web3.toWei(1, 'ether'));
			await contract.transfer(accountTwo, 10, {from: accountOne});

			var snapshotShares = await contract.getShapshotShares(i, { from: accountOne });
			assert.notEqual(snapshotShares, 0, 'shares must not be equal to 0');
		}
	});

	it('after withdraw snapshot shares becomes 0', async function() {
		for (var i = 0; i < 3; i++) {
			await contract.distribute(web3.toWei(1, 'ether'));
			await contract.transfer(accountTwo, 10, {from: accountOne});
		}

		await contract.withdraw({from: accountOne});

		for (var i = 0; i < 3; i++) {
			var snapshotShares = await contract.getShapshotShares(i, { from: accountOne });
			assert.equal(snapshotShares, 0, 'shares must be equal to 0');
		}
	});

	it('after withdraw last snapshot holds all balance', async function() {
		for (var i = 0; i < 3; i++) {
			await contract.distribute(web3.toWei(1, 'ether'));
			await contract.transfer(accountTwo, 10, {from: accountOne});
		}

		await contract.withdraw({from: accountOne});

		var snapshotCount = await contract.getSnapshotCount();

		var shares = await contract.getShapshotShares(snapshotCount - 1, { from: accountOne });
		assert.equal(shares.toNumber(), 10000 - 10 - 10 - 10, 'shares must be equal to 9970');
	});

	it('after withdrawUpTo snapshot shares becomes 0', async function() {
		var upToSnapshot = 3;
		for (var i = 0; i < 5; i++) {
			await contract.distribute(web3.toWei(1, 'ether'));
			await contract.transfer(accountTwo, 10, {from: accountOne});
		}

		await contract.withdrawUpTo(upToSnapshot, {from: accountOne});

		for (var i = 0; i < upToSnapshot; i++) {
			var snapshotShares = await contract.getShapshotShares(i, { from: accountOne });
			assert.equal(snapshotShares, 0, 'shares must be equal to 0');
		}
	});

	it('after withdrawUpTo "upTo" snapshot holds balance', async function() {
		var upToSnapshot = 3;

		for (var i = 0; i < 5; i++) {
			await contract.distribute(web3.toWei(1, 'ether'));
			await contract.transfer(accountTwo, 10, {from: accountOne});
		}

		await contract.withdrawUpTo(upToSnapshot, {from: accountOne});

		var shares = await contract.getShapshotShares(upToSnapshot, { from: accountOne });
		assert.equal(shares.toNumber(), 10000 - (10 * upToSnapshot), 'shares must be equal');
	});
});

contract('DigitalShares distribute small amounts of wei', async function(accounts) {
	var accountOne 		= accounts[0];
	var accountTwo 		= accounts[1];
	var accountThree 	= accounts[2];

	it('transfer -> distribute', async function() {
		var	contract = await TestDigitalShares.new(10);
		await contract.send(10);
		await contract.transfer(accountTwo, 	3, {from: accountOne});
		await contract.transfer(accountThree, 2, {from: accountOne});
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
		assert.equal(accountTwoBalance.toNumber(), 1, 'second account must have 1 wei dividends');
		assert.equal(accountThreeBalance.toNumber(), 1, 'third account must have 1 wei dividends');
	});

	it('transfer -> distribute -> withdraw -> distribute -> withdraw', async function() {
		var	contract = await TestDigitalShares.new(10);
		await contract.send(10);
		await contract.transfer(accountTwo, 	3, {from: accountOne});
		await contract.transfer(accountThree, 2, {from: accountOne});
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
		assert.equal(accountTwoBalance.toNumber(), 2, 'second account must have 2 wei dividends');
		assert.equal(accountThreeBalance.toNumber(), 1, 'third account must have 1 wei dividends');

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		assert.equal(contractBalance.toNumber(), 0, 'contract should have no wei left');
	});

	it('undistributed', async function() {
		var contract = await TestDigitalShares.new(30);
		await contract.send(web3.toWei(1, 'ether'));
		await contract.transfer(accountTwo, 10, {from: accountOne});
		await contract.transfer(accountThree, 10, {from: accountOne});

		await contract.distribute(web3.toWei(1, 'ether'));

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		assert.equal(contractBalance.toNumber(), 1, 'contract should have 1 wei left');
		var undistributed = await contract.getReserved.call();
		assert.equal(undistributed.toNumber(), 1, 'contract should have 1 wei undistributed');
	});

	it('unpayed 30', async function() {
		var contract = await TestDigitalShares.new(30);
		await contract.send(web3.toWei(1, 'ether'));
		await contract.transfer(accountTwo, 10, {from: accountOne});
		await contract.transfer(accountThree, 10, {from: accountOne});

		await contract.distribute(web3.toWei(1, 'ether'));

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var accountOneUnpayed = await contract.getUnpayedWei(accountOne);
		var accountTwoUnpayed = await contract.getUnpayedWei(accountTwo);
		var accountThreeUnpayed = await contract.getUnpayedWei(accountThree);

		assert.equal(10, accountOneUnpayed.toNumber(), '(10 shares * 1 ether) % 30 shares = 10 unpayed');
		assert.equal(10, accountTwoUnpayed.toNumber(), '(10 shares * 1 ether) % 30 shares = 10 unpayed');
		assert.equal(10, accountThreeUnpayed.toNumber(), '(10 shares * 1 ether) % 30 shares = 10 unpayed');
	});

	it('unpayed 99', async function() {
		var contract = await TestDigitalShares.new(99);
		await contract.send(web3.toWei(1, 'ether'));
		await contract.transfer(accountTwo, 10, {from: accountOne});
		await contract.transfer(accountThree, 33, {from: accountOne});

		await contract.distribute(web3.toWei(1, 'ether'));

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var accountOneUnpayed = await contract.getUnpayedWei(accountOne);
		var accountTwoUnpayed = await contract.getUnpayedWei(accountTwo);
		var accountThreeUnpayed = await contract.getUnpayedWei(accountThree);

		assert.equal(56, accountOneUnpayed.toNumber(), '(56 shares * 1 ether) % 99 shares = 56 unpayed');
		assert.equal(10, accountTwoUnpayed.toNumber(), '(10 shares * 1 ether) % 99 shares = 10 unpayed');
		assert.equal(33, accountThreeUnpayed.toNumber(), '(33 shares * 1 ether) % 99 shares = 33 unpayed');
	});

	it('unpayed 99 with 1.3333 ether', async function() {
		var contract = await TestDigitalShares.new(99);
		await contract.send(web3.toWei(1.3333, 'ether'));
		await contract.transfer(accountTwo, 10, {from: accountOne});
		await contract.transfer(accountThree, 33, {from: accountOne});

		await contract.distribute(web3.toWei(1.3333, 'ether'));

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		var accountOneUnpayed = await contract.getUnpayedWei(accountOne);
		var accountTwoUnpayed = await contract.getUnpayedWei(accountTwo);
		var accountThreeUnpayed = await contract.getUnpayedWei(accountThree);

		assert.equal(89, accountOneUnpayed.toNumber(), '(56 shares * 1.3333 ether) % 99 shares = 89 unpayed');
		assert.equal(76, accountTwoUnpayed.toNumber(), '(10 shares * 1.3333 ether) % 99 shares = 76 unpayed');
		assert.equal(33, accountThreeUnpayed.toNumber(), '(33 shares * 1.3333 ether) % 99 shares = 33 unpayed');

		assert.equal(2, contractBalance.toNumber(), '(89 + 76 + 33) / 99 = 2 wei left');
	});

	it('unpayed 99 with 4.687411 ether', async function() {
		var contract = await TestDigitalShares.new(99);
		await contract.send(web3.toWei(4.687411, 'ether'));
		await contract.transfer(accountTwo, 10, {from: accountOne});
		await contract.transfer(accountThree, 33, {from: accountOne});

		await contract.distribute(web3.toWei(4.687411, 'ether'));

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		var accountOneUnpayed = await contract.getUnpayedWei(accountOne);
		var accountTwoUnpayed = await contract.getUnpayedWei(accountTwo);
		var accountThreeUnpayed = await contract.getUnpayedWei(accountThree);

		assert.equal(80, accountOneUnpayed.toNumber(), '(56 shares * 4.687411 ether) % 99 shares = 80 unpayed');
		assert.equal(85, accountTwoUnpayed.toNumber(), '(10 shares * 4.687411 ether) % 99 shares = 85 unpayed');
		assert.equal(33, accountThreeUnpayed.toNumber(), '(33 shares * 4.687411 ether) % 99 shares = 33 unpayed');

		assert.equal(2, contractBalance.toNumber(), '(80 + 85 + 33) / 99 = 2 wei left');
	});

	it('unpayed 999 with 1.1 ether', async function() {
		var contract = await TestDigitalShares.new(999);
		await contract.send(web3.toWei(1.1, 'ether'));
		await contract.transfer(accountTwo, 111, {from: accountOne});
		await contract.transfer(accountThree, 333, {from: accountOne});

		await contract.distribute(web3.toWei(1.1, 'ether'));

		await contract.withdraw({from: accountOne});
		await contract.withdraw({from: accountTwo});
		await contract.withdraw({from: accountThree});

		var contractBalance = await web3.eth.getBalance(contract.address);
		var accountOneUnpayed = await contract.getUnpayedWei(accountOne);
		var accountTwoUnpayed = await contract.getUnpayedWei(accountTwo);
		var accountThreeUnpayed = await contract.getUnpayedWei(accountThree);

		assert.equal(111, accountOneUnpayed.toNumber(), '(555 shares * 1.1 ether) % 999 shares = 111 unpayed');
		assert.equal(222, accountTwoUnpayed.toNumber(), '(111 shares * 1.1 ether) % 999 shares = 222 unpayed');
		assert.equal(666, accountThreeUnpayed.toNumber(), '(333 shares * 1.1 ether) % 999 shares = 666 unpayed');

		assert.equal(1, contractBalance.toNumber(), '(111 + 222 + 666) / 999 = 1 wei left');
	});
});

contract('DigitalShares int256 max', async function(accounts) {
	var contract;
	var accountOne = accounts[0];
	var accountTwo = accounts[1];
	var int256Max = web3.toBigNumber('0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');

	beforeEach(async function() {
		contract = await TestDigitalShares.new(int256Max);
	});

	it('should successfully create contract with max int256', async function() {
		var accountOneBalance = await contract.balanceOf.call(accountOne);
		assert.isTrue(accountOneBalance.greaterThan(0), 'Owner balance is positive');
		assert.isTrue(accountOneBalance.equals(int256Max), 'Owner should have max int256 shares');
	});

	it('should successfully send max int256 shares', async function() {
		await contract.transfer(accountTwo, int256Max, {from: accountOne});
		var accountOneBalance = await contract.balanceOf.call(accountOne);
		var accountTwoBalance = await contract.balanceOf.call(accountTwo);
		assert.equal(accountOneBalance.toNumber(), 0, 'Owner should have 0 shares');
		assert.isTrue(accountTwoBalance.equals(int256Max), 'Account 2 should have int256 max shares');
	});

	it('should successfully send max int256 shares, distribute and send back', async function() {
		var transferAmount = int256Max;

		await contract.send(web3.toWei(1, 'ether'));
		await contract.transfer(accountTwo, transferAmount, {from: accountOne});
		await contract.distribute(web3.toWei(1, 'ether'));
		await contract.transfer(accountOne, transferAmount, {from: accountTwo});

		var accountOneBalance = await contract.balanceOf.call(accountOne);
		var accountTwoBalance = await contract.balanceOf.call(accountTwo);
		assert.isTrue(accountOneBalance.equals(int256Max), 'Owner should have int256 max shares');
		assert.equal(accountTwoBalance.toNumber(), 0, 'Account 2 should have no shares');

		var accountOneBalance = await contract.getCalculatedShares.call({from: accountOne});
		var accountTwoBalance = await contract.getCalculatedShares.call({from: accountTwo});
		assert.isTrue(accountOneBalance.equals(int256Max), 'Owner should have int256 max shares');
		assert.equal(accountTwoBalance.toNumber(), 0, 'Account 2 should have no shares');
	});

	it('should not send shares more than actually have', async function() {
		var transferAmount = int256Max.plus(1);

		await contract.transfer(accountTwo, transferAmount, {from: accountOne});
		var accountOneBalance = await contract.balanceOf.call(accountOne);
		var accountTwoBalance = await contract.balanceOf.call(accountTwo);
		assert.isTrue(accountOneBalance.equals(int256Max), 'Owner should still have int256 max shares');
		assert.equal(accountTwoBalance.toNumber(), 0, 'Account 2 should still have 0 shares');
	});

	it('contract should not be created with initial shares more that int256 max', async function() {
		try {
			var failing = await TestDigitalShares.new(int256Max.plus(1));
			assert.fail('Should not be here');
		}
		catch(e) {
			// expecting an exception
		}
	});

});