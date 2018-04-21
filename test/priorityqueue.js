const BigNumber = require('bignumber.js');

const chai = require('chai');
chai.use(require('chai-as-promised'));
chai.use(require('chai-bignumber')(BigNumber));

const expect = chai.expect;

const PriorityQueue = artifacts.require("../contracts/PriorityQueue.sol");

contract.only('PriorityQueue', async (accounts) => {
    let contract;

    before(async () => {
        contract = await PriorityQueue.new();
    });

    it('should store data item', async () => {
        await contract.push(1, 100);

        expect(await contract.size()).to.be.bignumber.equal(1);

        expect(await contract.takeMin.call()).to.be.bignumber.equal(100);
        await contract.takeMin();
    });


    it('should store additional 3 data items', async () => {
        await contract.push(4, 25);
        await contract.push(3, 50);
        await contract.push(2, 75);

        expect(await contract.size()).to.be.bignumber.equal(3);

        expect(await contract.takeMin.call()).to.be.bignumber.equal(75);
        await contract.takeMin();
    });

    it('should store additional many items', async () => {
        let sum = 0;
        let i;
        for (i = 0; i <= 1000; i++) {
            const tx = await contract.push(10000 - i, i * 3);
            sum += tx.receipt.gasUsed;
        }

        expect(await contract.takeMin.call()).to.be.bignumber.equal(50);
        const tx1 = await contract.takeMin();
        expect(await contract.takeMin.call()).to.be.bignumber.equal(25);
        const tx2 = await contract.takeMin();
        expect(await contract.takeMin.call()).to.be.bignumber.equal((i - 1) * 3);

        sum += tx1.receipt.gasUsed + tx2.receipt.gasUsed;
        console.log('Total gas:', sum);
    });

});
