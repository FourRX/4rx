const { accounts, contract } = require('@openzeppelin/test-environment');
const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time,
    constants,
} = require('@openzeppelin/test-helpers');

const { expect } = require('chai');
const [ owner, user1, user2 ] = accounts;

const FourRXFinance = contract.fromArtifact('FourRXFinance');
const ERC20 = contract.fromArtifact('DummyERC20Token');

describe('FourRXFinance Withdrawal Test', function () {
    beforeEach(async function() {
        this.amount = 10000;
        this.erc20 = await ERC20.new({ from: owner });
        this.fourRXFinance = await FourRXFinance.new(this.erc20.address, { from: owner });
        await this.erc20.transfer(user1, 1000000, { from: owner });
        await this.erc20.transfer(user2, 1000000, { from: owner });
        await this.erc20.approve(this.fourRXFinance.address, this.amount, {from: user1});
        await this.erc20.approve(this.fourRXFinance.address, this.amount, {from: user2});
        await this.fourRXFinance.deposit(this.amount, constants.ZERO_ADDRESS, {from: user1});
    })


    it('should allow withdrawal without penalty', async function () {
        await time.increase(time.duration.days(10));
        await this.fourRXFinance.deposit(this.amount, user1, {from: user2});

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(1111));
        // 36 hold rewards
        // 180 Contract rewards
        // 50 pool rewards (20 + 30)
        // 800 Referral rewards
        // 45 percentage rewards
        const receipt = await this.fourRXFinance.withdraw({from: user1});

        expectEvent(receipt, 'Withdraw', {
            user: user1,
            amount: new BN(211)
        })
    });

    it('should allow withdrawal with penalty', async function () {
        await time.increase(time.duration.days(10));

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(135));

        const receipt = await this.fourRXFinance.withdraw({from: user1});

        expectEvent(receipt, 'Withdraw', {
            user: user1,
            amount: new BN(21) // with 85% penalty
        })
    });

    it('should not allow two withdrawal same day', async function () {
        await time.increase(time.duration.days(10));

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(135));

        await this.fourRXFinance.withdraw({from: user1});
        await expectRevert.unspecified(this.fourRXFinance.withdraw({from: user1}));
    });

    it('should not allow more then 3% withdrawal same day', async function () {
        await time.increase(time.duration.days(200));

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(32538));

        const receipt = await this.fourRXFinance.withdraw({from: user1});

        expectEvent(receipt, 'Withdraw', {
            user: user1,
            amount: new BN(270) // with 0% penalty and only 3% of initial investment of 9000
        })
    });


    // @todo: Test with insurance as well
});
