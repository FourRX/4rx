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

describe('FourRXFinance Reinvest Test', function () {
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


    it('should allow re-invest since amount is less then available amount', async function () {
        await time.increase(time.duration.days(200));
        await this.fourRXFinance.deposit(this.amount, user1, {from: user2});

        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(33478));
        // @todo: this is buggy
        console.log((await this.fourRXFinance.balanceOf(user1)).toString());
        //
        // console.log(await this.fourRXFinance.getUser(user1));

        const receipt = await this.fourRXFinance.reInvest(500, {from: user1});

        console.log((await this.fourRXFinance.balanceOf(user1)).toString());
        //
        // console.log(await this.fourRXFinance.getUser(user1));

        expectEvent(receipt, 'ReInvest', {
            user: user1,
            amount: new BN(500)
        })
    });

    it('should not allow re-invest since amount is more then allowed amount', async function () {
        await time.increase(time.duration.days(200));
        expect(await this.fourRXFinance.balanceOf(user1)).to.be.bignumber.equals(new BN(32538));

        await expectRevert.unspecified(this.fourRXFinance.reInvest(32359, {from: user1})); // it'll allow to reinvest only the amount earned through interest
    });

    it('should not allow re-invest since amount is more then available amount', async function () {
        await time.increase(time.duration.days(10));
        await this.fourRXFinance.deposit(this.amount, user1, {from: user2});


        await expectRevert.unspecified(this.fourRXFinance.reInvest(10000, {from: user1}));
    });


    // @todo: Test with amount l
});
