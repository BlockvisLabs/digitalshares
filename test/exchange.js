const BigNumber = require('bignumber.js');

const chai = require('chai');
chai.use(require('chai-as-promised'));
chai.use(require('chai-bignumber')(BigNumber));

const expect = chai.expect;

const OneEther = new BigNumber(web3.toWei(1, 'ether'));
const OneToken = new BigNumber(web3.toWei(1, 'ether'));

const Exchange = artifacts.require("../test/TestExchange.sol");

contract.only('Exchange', async (accounts) => {
    let contract;
    const token = 0;

    before(async () => {
        contract = await Exchange.new();
        await contract.addPair(token);
    });

    it('stores bid', async () => {
        const lastOrderId = await contract.lastOrderId();
        const tx = await contract.buy(token, OneToken, OneEther.mul(0.5));

        expect(tx.logs[0].event).to.be.equal('NewOrder');
        expect(await contract.lastOrderId()).to.be.bignumber.equal(lastOrderId.add(1));
    });

    it('stores ask', async () => {
        const lastOrderId = await contract.lastOrderId();
        const tx = await contract.sell(token, OneToken, OneEther.mul(2));
        expect(tx.logs[0].event).to.be.equal('NewOrder');
        expect(await contract.lastOrderId()).to.be.bignumber.equal(lastOrderId.add(1));
    });

    it('stores more bids', async () => {
        await Promise.all([
            contract.buy(token, OneToken, OneEther.mul(0.1)),
            contract.buy(token, OneToken, OneEther.mul(0.2)),
            contract.buy(token, OneToken, OneEther.mul(0.3)),
            contract.buy(token, OneToken, OneEther.mul(0.4))
        ]);
        const [ amount, price ] = await contract.orders(await contract.getBestBid(token));
        expect(price).to.be.bignumber.equal(OneEther.mul(0.5));
    });

    it('stores more asks', async () => {
        await Promise.all([
            contract.sell(token, OneToken, OneEther.mul(2.1)),
            contract.sell(token, OneToken, OneEther.mul(2.2)),
            contract.sell(token, OneToken, OneEther.mul(2.3)),
            contract.sell(token, OneToken, OneEther.mul(2.4))
        ]);
        const [ amount, price ] = await contract.orders(await contract.getBestAsk(token));
        expect(price).to.be.bignumber.equal(OneEther.mul(2));
    });

    it('matches bid on price and amount', async () => {
        const tx = await contract.sell(token, OneToken, OneEther.mul(0.5));
        expect(tx.logs[1].event).to.be.equal('NewTrade');

        const [ amount, price ] = await contract.orders(await contract.getBestBid(token));
        expect(price).to.be.bignumber.equal(OneEther.mul(0.4));
    });

    it('matches bid on price, but amount is less', async () => {
        const asksSize = await contract.getAskQueueSize(token);
        const tx = await contract.sell(token, OneToken.mul(0.3), OneEther.mul(0.4));

        expect(tx.logs[1].event).to.be.equal('NewTrade');
        const [ amount, price ] = await contract.orders(await contract.getBestBid(token));
        expect(amount).to.be.bignumber.equal(OneToken.mul(0.7));
        expect(price).to.be.bignumber.equal(OneEther.mul(0.4));
        expect(await contract.getAskQueueSize(token)).to.be.bignumber.equal(asksSize);
    });

    it('matches bid on price, but amount is more', async () => {
        const asksSize = await contract.getAskQueueSize(token);
        const tx = await contract.sell(token, OneToken, OneEther.mul(0.4));

        expect(tx.logs[1].event).to.be.equal('NewAsk');
        expect(tx.logs[2].event).to.be.equal('NewTrade');
        const [ askAmount, askPrice ] = await contract.orders(await contract.getBestAsk(token));
        expect(askPrice).to.be.bignumber.equal(OneEther.mul(0.4));
        expect(askAmount).to.be.bignumber.equal(OneToken.mul(0.3));
        const [ amount, price ] = await contract.orders(await contract.getBestBid(token));
        expect(price).to.be.bignumber.equal(OneEther.mul(0.3));
        expect(amount).to.be.bignumber.equal(OneToken);
        expect(await contract.getAskQueueSize(token)).to.be.bignumber.equal(asksSize.add(1));
    });

    it('matches bid on less price and exact amount', async () => {
        const asksSize = await contract.getAskQueueSize(token);
        const tx = await contract.sell(token, OneToken, OneEther.mul(0.25));

        expect(tx.logs[1].event).to.be.equal('NewTrade');

        const [ amount, price ] = await contract.orders(await contract.getBestBid(token));
        expect(amount).to.be.bignumber.equal(OneToken);
        expect(price).to.be.bignumber.equal(OneEther.mul(0.2));
        expect(await contract.getAskQueueSize(token)).to.be.bignumber.equal(asksSize);
    });


});
