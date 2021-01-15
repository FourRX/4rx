const dummyERC20Token = artifacts.require("DummyERC20Token");
const fourRXFinance = artifacts.require("FourRXFinance");

module.exports = async function (deployer) {
  await deployer.deploy(dummyERC20Token);
  await deployer.deploy(fourRXFinance, dummyERC20Token.address);
};
