var TestP = artifacts.require("../test/TestP.sol");

contract('TestP', async function(accounts) {
	let contract;
	beforeEach(async function() {
		contract = await TestP.new();
	});

	it('should test 1', async function() {
		let tx = await contract.setValue(1);
		console.log('setValue(1): ' + tx.receipt.gasUsed);
		tx = await contract.traverse();
		console.log('traverse(): ' + tx.receipt.gasUsed);
		tx = await contract.setAll();
		console.log('setAll(): ' + tx.receipt.gasUsed);
		tx = await contract.reset();
		console.log('reset(): ' + tx.receipt.gasUsed);
	});

	it('should test 10', async function() {
		for (let i = 0; i < 10; i++) {
			await contract.setValue(1);
		}
		let tx = await contract.traverse();
		console.log('traverse(): ' + tx.receipt.gasUsed);
		tx = await contract.setAll();
		console.log('setAll(): ' + tx.receipt.gasUsed);
		tx = await contract.reset();
		console.log('reset(): ' + tx.receipt.gasUsed);
	});

	it('should set other value', async function() {
		let tx = await contract.setOtherValue(10);
		console.log('setOtherValue(10): ' + tx.receipt.gasUsed);
		tx = await contract.setOtherValue(20);
		console.log('setOtherValue(20): ' + tx.receipt.gasUsed);
		tx = await contract.setOtherValue(0);
		console.log('setOtherValue(0): ' + tx.receipt.gasUsed);
	});

	it('should call rewrite', async function() {
		let tx = await contract.rewrite(2);
		console.log('rewrite(2): ' + tx.receipt.gasUsed);
		tx = await contract.rewrite(2);
		console.log('rewrite(2): ' + tx.receipt.gasUsed);
		tx = await contract.rewrite(3);
		console.log('rewrite(3): ' + tx.receipt.gasUsed);
		tx = await contract.rewrite(3);
		console.log('rewrite(3): ' + tx.receipt.gasUsed);
	});
});