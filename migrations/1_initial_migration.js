const frxToken = artifacts.require("FRX");
const fourRXFinance = artifacts.require("FourRXFinance");

module.exports = async function (deployer) {
  await deployer.deploy(frxToken);
  await deployer.deploy(fourRXFinance, frxToken.address);
};
