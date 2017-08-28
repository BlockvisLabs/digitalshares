var DigitalShares = artifacts.require("../DigitalShares.sol");

contract('DigitalShares Gas Consumtion Tests', async function(accounts) {
	var contract;
	beforeEach(async function() {
		contract = await DigitalShares.new(10000);
		await contract.send(web3.toWei(10, 'ether'));
		// for(var i = 1; i < accounts.length; i++) {
		// 	await contract.transfer(accounts[i], 10, {from: accounts[0]});
		// }
	});

	it('test distribute', async function() {
		var tx = await contract.distribute(web3.toWei(1000, 'wei'));
		console.log(tx);
	});

	it('test withdraw 1', async function() {
		await contract.distribute(web3.toWei(1000, 'wei'));
		var tx = await contract.withdraw({from: accounts[0]});
		console.log(tx);
	});

	it('test withdraw 10 distributions', async function() {
		for(var i = 0; i < 10; i++) {
			await contract.distribute(web3.toWei(1000, 'wei'));
		}
		var tx = await contract.withdraw({from: accounts[0]});
		console.log(tx);
	});

	// it('test withdraw 100 distributions', async function() {
	// 	for(var i = 0; i < 100; i++) {
	// 		await contract.distribute(web3.toWei(1000, 'wei'));
	// 	}
	// 	var tx = await contract.withdraw({from: accounts[0]});
	// 	console.log(tx);
	// });

	// it('test withdraw 1000 distributions', async function() {
	// 	for(var i = 0; i < 1000; i++) {
	// 		await contract.distribute(web3.toWei(1000, 'wei'));
	// 	}
	// 	var tx = await contract.withdraw({from: accounts[0]});
	// 	console.log(tx);
	// });

});