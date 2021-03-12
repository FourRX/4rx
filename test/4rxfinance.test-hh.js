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
        const Token = await ethers.getContractFactory("FRX");
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
        this.timeout(50000);
        const [user1, user2] = await ethers.getSigners();
        const amount = 10000;
        await this.erc20.transfer(user1.address, 1000000);
        await this.erc20.transfer(user2.address, 1000000);
        await this.erc20.connect(user1).approve(this.fourRXFinance.address, amount + 10000);
        await this.erc20.connect(user2).approve(this.fourRXFinance.address, amount + 10000);
        await this.fourRXFinance.connect(user1).deposit(amount, constants.ZERO_ADDRESS, 0);

        await network.provider.send('evm_increaseTime', [10*86400])
        // await time.increase(time.duration.days(10));
        await this.fourRXFinance.connect(user2).deposit(amount, user1.address, 0);
        await this.fourRXFinance.connect(user2).insureStake(0);

        while (!(await this.fourRXFinance.getContractInfo())[1]) {
            // await time.increase(time.duration.days(5));
            await network.provider.send('evm_increaseTime', [5*86400])
            await this.fourRXFinance.connect(user1).withdraw(0);
            if (!(await this.fourRXFinance.getContractInfo())[1]) {
                await this.fourRXFinance.connect(user2).withdraw(0);
            }
        }

        expect((await this.fourRXFinance.getContractInfo())[1]).to.be.equals(true);
        await expectRevert.unspecified(this.fourRXFinance.connect(user1).withdraw(0));

        const user1Details = await this.fourRXFinance.getUser(user1.address);
        const user2Details = await this.fourRXFinance.getUser(user2.address);
        //
        await this.fourRXFinance.connect(user2).withdraw(0);

        // console.log((await this.erc20.balanceOf(this.fourRXFinance.address)).toString());

        // console.log(user1Details, user2Details);

        // console.log((await this.fourRXFinance.getContractInfo())[0].toString());
    });
});
