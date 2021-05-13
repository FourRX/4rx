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

const FRXFarm = contract.fromArtifact('FrxFarm');
const ERC20 = contract.fromArtifact('FRX');
const StrategyFRX = contract.fromArtifact('StrategyFRX');

const MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6";

const decimalZeros = '00000000'

describe('FRXFarm Tests', function () {
    beforeEach(async function() {

        this.frx = await ERC20.new({ from: owner });

        await this.frx.transfer(user1, `1000000${decimalZeros}`, { from: owner });
        await this.frx.transfer(user2, `1000000${decimalZeros}`, { from: owner });
        await this.frx.transfer(user3, `1000000${decimalZeros}`, { from: owner });

        this.frxFarm = await FRXFarm.new(this.frx.address, { from: owner });
        await this.frx.grantRole(MINTER_ROLE, this.frxFarm.address, {from: owner});

        this.strategy = await StrategyFRX.new(
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
            this.frx.address,
            {from: owner}
        );

        this.frxFarm.add(100, this.frx.address, true, this.strategy.address, {from: owner});
    })

    it('Deposit Test', async function () {
        await this.frx.approve(this.frxFarm.address, `1000${decimalZeros}`, { from: user1 });
        await this.frxFarm.deposit(0, `1000${decimalZeros}`, { from: user1 });

        await time.increase(10000000);

        await this.frx.approve(this.frxFarm.address, `1000${decimalZeros}`, { from: user2 });

        await this.frxFarm.deposit(0, `1000${decimalZeros}`, { from: user2 });

        console.log(await this.frxFarm.pendingFRX(0, user1));
    });

});
