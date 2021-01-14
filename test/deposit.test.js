const { accounts, contract } = require('@openzeppelin/test-environment');
const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time,
    constants
} = require('@openzeppelin/test-helpers');

const { expect } = require('chai');
const [ owner, user1, user2, user3 ] = accounts;

const FourRXFinance = contract.fromArtifact('FourRXFinance');
const ERC20 = contract.fromArtifact('DummyERC20Token');

describe('FourRXFinance Test', function () {
    beforeEach(async function() {
        this.amount = 10000;
        this.erc20 = await ERC20.new({ from: owner });
        this.fourRXFinance = await FourRXFinance.new(this.erc20.address, { from: owner });
        await this.erc20.transfer(user1, 1000000, { from: owner });
        await this.erc20.transfer(user2, 1000000, { from: owner });
        await this.erc20.transfer(user3, 1000000, { from: owner });
        await this.erc20.approve(this.fourRXFinance.address, this.amount, {from: user1});
        await this.erc20.approve(this.fourRXFinance.address, this.amount, {from: user2});
        await this.erc20.approve(this.fourRXFinance.address, this.amount, {from: user3});
        await this.fourRXFinance.deposit(this.amount, constants.ZERO_ADDRESS, {from: user1});
    })

    it('should give referrer 10% of deposit ', async function () {

        const receipt = await this.fourRXFinance.deposit(this.amount, user1, {from: user2});
        // Expect user to be registered successfully
        expectEvent(receipt, 'Deposit', {
            user: user2,
            uplink: user1,
            amount: new BN(this.amount)
        })

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(1180)); // Ref Bonus 1000 + 180 Contract Rewards (2% of user's balance after removing lp commissions)
    });

    it('should give user rewards in 10 days', async function () {
        await time.increase(time.duration.days(10));

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(135));
        // 90 contract rewaards
        // 45 percentage rewards
    });

    it('should give user pool rewards and 10 days rewards', async function () {
        await time.increase(time.duration.days(10));
        await this.fourRXFinance.deposit(this.amount, user1, {from: user2});

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(1311));
        // 36 hold rewards
        // 180 Contract rewards
        // 50 pool rewards (20 + 30)
        // 1000 Referral rewards
        // 45 percentage rewards
    });

    // test rewards based on pool draws
});
