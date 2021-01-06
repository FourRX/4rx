const { accounts, contract } = require('@openzeppelin/test-environment');
const {
    BN,           // Big Number support
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
    time
} = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

const FourRXFinance = contract.fromArtifact('FourRXFinance');
const ERC20 = contract.fromArtifact('DummyERC20Token');

describe('FourRXFinance Test', function () {
    beforeEach(async function() {
        this.erc20 = await ERC20.new();
        this.fourRXFinance = await FourRXFinance.new(this.erc20.address);
    })

    it('should print log value', async function () {
        console.log("reached here")
        const x = await this.fourRXFinance.calcInterest(10);
        const x2 = await this.fourRXFinance.calcInterest(1);
        const x3 = await this.fourRXFinance.calcInterest(3);
        const x4 = await this.fourRXFinance.calcInterest(5);
        const x5 = await this.fourRXFinance.calcInterest(7);
        const y = await this.fourRXFinance.calcInterest(50);
        const y1 = await this.fourRXFinance.calcInterest(70);
        const y2 = await this.fourRXFinance.calcInterest(86);
        const y3 = await this.fourRXFinance.calcInterest(90);
        const y4 = await this.fourRXFinance.calcInterest(100);
        // const z = await this.fourRXFinance.calcInterest(150);
        // console.log(x2['0'].toString(), x2['1'].toString());
        // console.log(x3['0'].toString(), x3['1'].toString());
        // console.log(x4['0'].toString(), x4['1'].toString());
        // console.log(x5['0'].toString(), x5['1'].toString());
        // console.log(x['0'].toString(), x['1'].toString());
        // console.log(y['0'].toString(), y['1'].toString());
        // console.log(z['0'].toString(), z['1'].toString());
        console.log(x2.toString());
        console.log(x3.toString());
        console.log(x4.toString());
        console.log(x5.toString());
        console.log(x.toString());
        console.log(y.toString());
        console.log(y1.toString());
        console.log(y2.toString());
        console.log(y3.toString());
        console.log(y4.toString());
        console.log(y.toString());
        // console.log(z.toString());
    })
});
