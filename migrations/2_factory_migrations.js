var ERC223TokenFactory = artifacts.require("ERC223TokenFactory");

module.exports = function(deployer) {
  deployer.deploy(ERC223TokenFactory);
};