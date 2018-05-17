const CommunityTokenFactory = artifacts.require("CommunityTokenFactory");
const GluonToken = artifacts.require("GluonToken");


module.exports = function(deployer) {
  deployer.deploy(CommunityTokenFactory, GluonToken.address);
};
