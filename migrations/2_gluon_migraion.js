const GluonToken = artifacts.require("GluonToken");

const NAME = 'Gluon'
const DECIMALS = 18
const SYMBOL = 'GLU'
const EXPONENT = 2


module.exports = function(deployer) {
  deployer.deploy(GluonToken, NAME, DECIMALS, SYMBOL, EXPONENT);
};
