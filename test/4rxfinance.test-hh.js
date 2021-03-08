const { expect } = require("chai");

const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time,
    constants
} = require('@openzeppelin/test-helpers');


describe('FourRXFinance Registration Test', function () {
    beforeEach(async function() {
        /*this.erc20 = await ERC20.new({ from: owner });
        this.fourRXFinance = await FourRXFinance.new(this.erc20.address, { from: owner });
        await this.erc20.transfer(user1, 1000000, { from: owner });*/
        const Token = await ethers.getContractFactory("DummyERC20Token");
        this.erc20 = await Token.deploy();
        const FourRX = await ethers.getContractFactory("FourRXFinance");

        this.fourRXFinance = await FourRX.deploy(this.erc20.address);

        console.log(this.fourRXFinance.address);
    })

    /*it('should revert since user has not approve any deposit to contract', async function () {
        await expectRevert(
            this.fourRXFinance.deposit(1000, constants.ZERO_ADDRESS, 0),
            'ERC20: transfer amount exceeds balance.'
        );
    });*/

    it('should allow user to register and make a deposit successfully', async function () {
        const amount = 1000;
        let receipt = await this.erc20.approve(this.fourRXFinance.address, amount);

        /*expectEvent(receipt, 'Approval', {
            owner: user1,
            spender: this.fourRXFinance.address,
            value: new BN(amount)
        })*/

        receipt = await this.fourRXFinance.deposit(amount, constants.ZERO_ADDRESS, 0);

        // console.log(receipt);

        // expectEvent(receipt, 'Deposit', {
        //     user: user1,
        //     uplink: constants.ZERO_ADDRESS,
        //     amount: new BN(amount)
        // })
    });
});
