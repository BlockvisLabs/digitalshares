var DigitalSharesExchange = artifacts.require("contracts/DigitalSharesExchange.sol");

contract('DigitalSharesExchange', async function(accounts) {
	var contract;
	var accountOne = accounts[0];
	var accountTwo = accounts[1];
	var exchange = accounts[2];

	beforeEach(async function() {
		contract = await DigitalSharesExchange.new(10000);
	});

	it('all shares must be initially available', async function() {
		var available = await contract.getAvailableBalance();
		assert.equal(available.toNumber(), 10000);
	});

	it('available shares must decrease after exchangeApprove', async function() {
		await contract.exchangeApprove(exchange, 100);
		var available = await contract.getAvailableBalance();
		assert.equal(available.toNumber(), 9900);
	});

	it('should show exchangeAllowance', async function() {
		var blockedAmount = 1000;
		await contract.exchangeApprove(exchange, blockedAmount, {from: accountOne});

		var exchangeAllowance = await contract.exchangeAllowance(accountOne, exchange);
		assert.equal(exchangeAllowance.toNumber(), blockedAmount);
	});

	it('transfer should success when moving less than blocked', async function() {
		var blockedAmount = 1000;
		await contract.exchangeApprove(exchange, blockedAmount);
		await contract.transfer(accountTwo, 2000, {from: accountOne});
		var balance = await contract.balanceOf(accountOne);
		assert.equal(balance.toNumber(), 8000);
		var available = await contract.getAvailableBalance();
		assert.equal(available.toNumber(), 7000);
	});

	it('should block shares on another account after exchangeTransfer', async function() {
		var blockedAmount = 1000;
		await contract.exchangeApprove(exchange, blockedAmount, {from: accountOne});
		await contract.exchangeTransfer(accountOne, accountTwo, blockedAmount, {from: exchange});

		var accountOneBalance = await contract.balanceOf(accountOne);
		var accountTwoBalance = await contract.balanceOf(accountTwo);
		assert.equal(accountOneBalance.toNumber(), 9000);
		assert.equal(accountTwoBalance.toNumber(), 1000);

		var accountOneAvailable = await contract.getAvailableBalance({from: accountOne});
		var accountTwoAvailable = await contract.getAvailableBalance({from: accountTwo});
		var exchangeAllowance = await contract.exchangeAllowance(accountTwo, exchange);
		assert.equal(accountOneAvailable.toNumber(), 9000);
		assert.equal(accountTwoAvailable.toNumber(), 0);
		assert.equal(exchangeAllowance.toNumber(), blockedAmount);
	});

	it('should unblock shares on another account after exchangeReturn', async function() {
		var blockedAmount = 1000;
		await contract.exchangeApprove(exchange, blockedAmount, {from: accountOne});
		await contract.exchangeTransfer(accountOne, accountTwo, blockedAmount, {from: exchange});
		await contract.exchangeReturn(accountTwo, blockedAmount, {from: exchange});

		var accountTwoAvailable = await contract.getAvailableBalance({from: accountTwo});
		assert.equal(accountTwoAvailable.toNumber(), 1000);
	});

	it('should be possible to distribute while shares are blocked on exchange', async function() {
		var blockedAmount = 1000;
		await contract.send(web3.toWei(1, 'ether'));
		await contract.exchangeApprove(exchange, blockedAmount, {from: accountOne});
		await contract.transfer(accountTwo, 1000, {from: accountOne});

		await contract.distribute(web3.toWei(1, 'ether'));

	});

	// exchangeTransfer on empty approve
	// distribute when blocked
});