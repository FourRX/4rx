const { expect } = require("chai");

const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time,
    constants
} = require('@openzeppelin/test-helpers');

const decimalZeros = '00000000'
const MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6";

describe('FRX Farm test', function () {
    beforeEach(async function() {
        /*this.erc20 = await ERC20.new({ from: owner });
        this.fourRXFinance = await FourRXFinance.new(this.erc20.address, { from: owner });
        await this.erc20.transfer(user1, 1000000, { from: owner });*/

        const Token = await ethers.getContractFactory("FRX");
        this.frx = await Token.deploy();

        const FRXFarm = await ethers.getContractFactory("FrxFarm");

        this.frxFarm = await FRXFarm.deploy(this.frx.address);

        await this.frx.grantRole(MINTER_ROLE, this.frxFarm.address);

        const StrategyFRX = await ethers.getContractFactory("StrategyFrx");

        this.strategy = await StrategyFRX.deploy(
            this.frxFarm.address,
            this.frx.address,
            false,
            false,
            this.frxFarm.address,
            0,
            this.frx.address,
            this.frx.address,
            this.frx.address,
            this.frx.address,
            this.frx.address
        );

        this.frxFarm.add(100, this.frx.address, true, this.strategy.address);
    })

    it('Should allow users to deposit in farm', async function () {
        const [user1, user2, user3] = await ethers.getSigners();
        await this.frx.transfer(user1.address, `1000000${decimalZeros}`);
        await this.frx.transfer(user2.address, `1000000${decimalZeros}`);
        await this.frx.transfer(user3.address, `1000000${decimalZeros}`);

        await this.frx.connect(user1).approve(this.frxFarm.address, `1000${decimalZeros}`);
        await this.frxFarm.connect(user1).deposit(0, `1000${decimalZeros}`);

        // await time.increase(10000000);

        await this.frx.connect(user2).approve(this.frxFarm.address, `1000${decimalZeros}`);

        await this.frxFarm.connect(user2).deposit(0, `1000${decimalZeros}`);

        // console.log(await this.frxFarm.pendingFRX(0, user1));
    });

});
