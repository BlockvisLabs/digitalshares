const BigNumber = require('bignumber.js');

const chai = require('chai');
chai.use(require('chai-as-promised'));
chai.use(require('chai-bignumber')(BigNumber));

const expect = chai.expect;

const TestDigitalSecurities = artifacts.require("test/TestDigitalSecurities.sol");

const OneEther = new BigNumber(web3.toWei(1, 'ether'));
const OneToken = new BigNumber(1);

contract('DigitalSecurities', async (accounts) => {
	let contract;
	let accountOne = accounts[0];
	let accountTwo = accounts[1];

	beforeEach(async () => {
		contract = await TestDigitalSecurities.new(OneToken.mul(10000));
		await contract.send(OneEther.mul(10));
	});

	it('should successfully create contract', async () => expect(await contract.balanceOf(accountOne)).to.be.bignumber.equal(OneToken.mul(10000)));

	it('should successfully send shares', async () => {
		await contract.transfer(accountTwo, OneToken.mul(1000), {from: accountOne});

        expect(await contract.balanceOf(accountOne)).to.be.bignumber.equal(OneToken.mul(9000));
        expect(await contract.balanceOf(accountTwo)).to.be.bignumber.equal(OneToken.mul(1000));
	});

	it('should not send more shares than actually have', async () => {
        await expect(contract.transfer(accountTwo, OneToken.mul(10001), {from: accountOne})).eventually.rejected;
	});

	it('should distribute dividends', async () => {
		await contract.transfer(accountTwo, OneToken.mul(1000), {from: accountOne});
		await contract.distribute(OneEther.mul(10), {from: accountOne});

        expect(await contract.getDividends(accountOne)).to.be.bignumber.equal(OneEther.mul(9));
        expect(await contract.getDividends(accountTwo)).to.be.bignumber.equal(OneEther);
	});

	it('should fail to distribute more dividends than have ether on balance', async () => {
		await expect(contract.distribute(OneEther.mul(10).add(1), {from: accountOne})).eventually.rejected;

        expect(await contract.getDividends(accountOne)).to.be.bignumber.equal(0);
	});

	it('transfer -> no distribute', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), { from: accountOne });

        expect(await contract.getDividends(accountOne)).to.be.bignumber.equal(0);
	});

	it('transfer -> distribute', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		const balanceBeforeOne = await contract.getDividends(accountOne);
		const balanceBeforeTwo = await contract.getDividends(accountTwo);

		await contract.distribute(OneEther, {from: accountOne});
        const balanceAfterOne = await contract.getDividends(accountOne);
		const balanceAfterTwo = await contract.getDividends(accountTwo);

        expect(balanceAfterOne.sub(balanceBeforeOne)).to.be.bignumber.equal(OneEther.mul(0.5));
        expect(balanceAfterTwo.sub(balanceBeforeTwo)).to.be.bignumber.equal(OneEther.mul(0.5));
	});

	it('transfer -> distribute -> distribute', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		const balanceBeforeOne = await contract.getDividends(accountOne);
		const balanceBeforeTwo = await contract.getDividends(accountTwo);
		await contract.distribute(OneEther, {from: accountOne});
		await contract.distribute(OneEther, {from: accountOne});

		const balanceAfterOne = await contract.getDividends(accountOne);
		const balanceAfterTwo = await contract.getDividends(accountTwo);

        expect(balanceAfterOne.sub(balanceBeforeOne)).to.be.bignumber.equal(OneEther);
        expect(balanceAfterTwo.sub(balanceBeforeTwo)).to.be.bignumber.equal(OneEther);
	});

	it('withdraw', async () => {
		const accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.withdraw({from: accountTwo});

        expect(await web3.eth.getBalance(accountTwo)).to.be.bignumber.below(accountTwoBalanceBefore);
	});

	it('transfer -> withdraw', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		const accountOneBalanceBefore = await web3.eth.getBalance(accountOne);

        await contract.withdraw({from: accountOne});

        expect(await web3.eth.getBalance(accountOne)).to.be.bignumber.below(accountOneBalanceBefore);
	});

	it('transfer -> distribute -> withdraw', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		const accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(OneEther);
		await contract.withdraw({from: accountTwo});

		const accountTwoBalanceAfter = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After: ' + web3.fromWei(accountTwoBalanceAfter.toNumber(), 'ether'));

        expect(accountTwoBalanceAfter).to.be.bignumber.above(accountTwoBalanceBefore);
	});

	it('transfer -> distribute -> distribute -> withdraw', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		const accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(OneEther);
		await contract.distribute(OneEther);
		await contract.withdraw({from: accountTwo});

		const accountTwoBalanceAfter = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After: ' + web3.fromWei(accountTwoBalanceAfter.toNumber(), 'ether'));
        expect(accountTwoBalanceAfter).to.be.bignumber.above(accountTwoBalanceBefore);
	});

	it('transfer -> distribute -> withdraw -> withdraw', async () => {
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		const accountTwoBalanceBefore = await web3.eth.getBalance(accountTwo);
		await contract.distribute(OneEther);
		await contract.withdraw({from: accountTwo}); // this call receives distributed ether

		const accountTwoBalanceAfter1 = await web3.eth.getBalance(accountTwo);
		console.log('Before: ' + web3.fromWei(accountTwoBalanceBefore.toNumber(), 'ether'));
		console.log('After 1: ' + web3.fromWei(accountTwoBalanceAfter1.toNumber(), 'ether'));
		await contract.withdraw({from: accountTwo}); // this call only consumes gas

		const accountTwoBalanceAfter2 = await web3.eth.getBalance(accountTwo);
		console.log('After 2: ' + web3.fromWei(accountTwoBalanceAfter2.toNumber(), 'ether'));
        expect(accountTwoBalanceAfter1).to.be.bignumber.above(accountTwoBalanceAfter2);
	});

	it('transfer -> distribute -> transfer -> distribute', async () => {
		const accountThree = accounts[2];
		await contract.transfer(accountTwo, OneToken.mul(5000), {from: accountOne});
		await contract.distribute(OneEther);
		await contract.transfer(accountThree, OneToken.mul(5000), {from: accountTwo});
		await contract.distribute(OneEther);

        expect(await contract.getDividends(accountOne)).to.be.bignumber.equal(OneEther);
        expect(await contract.getDividends(accountTwo)).to.be.bignumber.equal(OneEther.mul(0.5));
        expect(await contract.getDividends(accountThree)).to.be.bignumber.equal(OneEther.mul(0.5));
	});
});

contract('DigitalSecurities distribute small amounts of wei', async function(accounts) {
	const accountOne 		= accounts[0];
	const accountTwo 		= accounts[1];
    const accountThree 	       = accounts[2];

	it('transfer -> distribute', async () => {
		var	contract = await TestDigitalSecurities.new(OneToken.mul(10));
		await contract.send(10); // 10 wei
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(3), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(2), {from: accountOne})
        ]);
		for (let i = 0; i < 5; i++) {
			await contract.distribute(1); // one wei
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
        expect(await contract.getDividends(accountOne)).to.be.bignumber.equal(2);
        expect(await contract.getDividends(accountTwo)).to.be.bignumber.equal(1);
        expect(await contract.getDividends(accountThree)).to.be.bignumber.equal(1);
	});

	it('transfer -> distribute -> withdraw -> distribute -> withdraw', async () => {
		var	contract = await TestDigitalSecurities.new(OneToken.mul(10));
		await contract.send(10);
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(3), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(2), {from: accountOne})
        ]);
		for (let i = 0; i < 5; i++) {
			await contract.distribute(1); // 1 wei
		}
		/**
		 * same share and dividend distribution as above
		 */
        await Promise.all([
            contract.withdraw({from: accountOne}),
    		contract.withdraw({from: accountTwo}),
    		contract.withdraw({from: accountThree})
        ]);
        expect(await web3.eth.getBalance(contract.address)).to.be.bignumber.equal(6); // contract should have 6 wei left

		for (let i = 0; i < 5; i++) {
			await contract.distribute(1);
		}

		/**
		 * dividend distribution:
		 * accountOne: 0.5 wei + (5 * 5) / 10 = 3, 0 wei left
		 * accountTwo: 0.5 wei + (3 * 5) / 10 = 2, 0 wei left
		 * accountThree: 0 wei + (2 * 5) / 10 = 1, 0 wei left
		 */

        expect(await contract.getDividends(accountOne)).to.be.bignumber.equal(3);
        expect(await contract.getDividends(accountTwo)).to.be.bignumber.equal(2);
        expect(await contract.getDividends(accountThree)).to.be.bignumber.equal(1);

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

        expect(await web3.eth.getBalance(contract.address)).to.be.bignumber.equal(0);
	});

	it('undistributed', async () => {
		const contract = await TestDigitalSecurities.new(OneToken.mul(30));
		await contract.send(OneEther);
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(10), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(10), {from: accountOne})
        ]);

		await contract.distribute(OneEther);

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

        expect(await web3.eth.getBalance(contract.address)).to.be.bignumber.equal(1);
        expect(await contract.getReserved()).to.be.bignumber.equal(1);
	});

	it('unpaid 30', async () => {
		const contract = await TestDigitalSecurities.new(OneToken.mul(30));
		await contract.send(OneEther);
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(10), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(10), {from: accountOne})
        ]);

		await contract.distribute(OneEther);

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

		expect(await contract.getUnpaidWei(accountOne)).to.be.bignumber.equal(10); // (10 shares * 1 ether) % 30 shares = 10 unpaid
		expect(await contract.getUnpaidWei(accountTwo)).to.be.bignumber.equal(10); // (10 shares * 1 ether) % 30 shares = 10 unpaid
		expect(await contract.getUnpaidWei(accountThree)).to.be.bignumber.equal(10); // (10 shares * 1 ether) % 30 shares = 10 unpaid
	});

	it('unpaid 99', async () => {
		const contract = await TestDigitalSecurities.new(OneToken.mul(99));
		await contract.send(OneEther);
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(10), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(33), {from: accountOne})
        ]);

		await contract.distribute(OneEther);

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

		expect(await contract.getUnpaidWei(accountOne)).to.be.bignumber.equal(56); // (56 shares * 1 ether) % 99 shares = 56 unpaid
		expect(await contract.getUnpaidWei(accountTwo)).to.be.bignumber.equal(10); // (10 shares * 1 ether) % 99 shares = 10 unpaid
		expect(await contract.getUnpaidWei(accountThree)).to.be.bignumber.equal(33); // (33 shares * 1 ether) % 99 shares = 33 unpaid
	});

	it('unpaid 99 with 1.3333 ether', async () => {
		const contract = await TestDigitalSecurities.new(OneToken.mul(99));
		await contract.send(OneEther.mul(1.3333));
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(10), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(33), {from: accountOne})
        ]);

		await contract.distribute(OneEther.mul(1.3333));

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

		expect(await contract.getUnpaidWei(accountOne)).to.be.bignumber.equal(89); // (56 shares * 1.3333 ether) % 99 shares = 89 unpaid'
		expect(await contract.getUnpaidWei(accountTwo)).to.be.bignumber.equal(76); // (10 shares * 1.3333 ether) % 99 shares = 76 unpaid'
		expect(await contract.getUnpaidWei(accountThree)).to.be.bignumber.equal(33); // (33 shares * 1.3333 ether) % 99 shares = 33 unpaid'
		expect(await web3.eth.getBalance(contract.address)).to.be.bignumber.equal(2); // (89 + 76 + 33) / 99 = 2 wei left'
	});

	it('unpaid 99 with 4.687411 ether', async () => {
		const contract = await TestDigitalSecurities.new(OneToken.mul(99));
		await contract.send(OneEther.mul(4.687411));
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(10), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(33), {from: accountOne})
        ]);

		await contract.distribute(OneEther.mul(4.687411));

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

		expect(await contract.getUnpaidWei(accountOne)).to.be.bignumber.equal(80); // (56 shares * 4.687411 ether) % 99 shares = 80 unpaid
		expect(await contract.getUnpaidWei(accountTwo)).to.be.bignumber.equal(85); // (10 shares * 4.687411 ether) % 99 shares = 85 unpaid
		expect(await contract.getUnpaidWei(accountThree)).to.be.bignumber.equal(33); // (33 shares * 4.687411 ether) % 99 shares = 33 unpaid
		expect(await web3.eth.getBalance(contract.address)).to.be.bignumber.equal(2); // (80 + 85 + 33) / 99 = 2 wei left
	});

	it('unpaid 999 with 1.1 ether', async () => {
		const contract = await TestDigitalSecurities.new(OneToken.mul(999));
		await contract.send(OneEther.mul(1.1));
        await Promise.all([
            contract.transfer(accountTwo, OneToken.mul(111), {from: accountOne}),
            contract.transfer(accountThree, OneToken.mul(333), {from: accountOne})
        ]);

		await contract.distribute(OneEther.mul(1.1));

        await Promise.all([
            contract.withdraw({from: accountOne}),
            contract.withdraw({from: accountTwo}),
            contract.withdraw({from: accountThree})
        ]);

        expect(await contract.getUnpaidWei(accountOne)).to.be.bignumber.equal(111); // (555 shares * 1.1 ether) % 999 shares = 111 unpaid
		expect(await contract.getUnpaidWei(accountTwo)).to.be.bignumber.equal(222); // (111 shares * 1.1 ether) % 999 shares = 222 unpaid
		expect(await contract.getUnpaidWei(accountThree)).to.be.bignumber.equal(666); // (333 shares * 1.1 ether) % 999 shares = 666 unpaid
		expect(await web3.eth.getBalance(contract.address)).to.be.bignumber.equal(1); // (111 + 222 + 666) / 999 = 1 wei left
	});
});
