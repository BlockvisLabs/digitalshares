var SafeMath = artifacts.require("./SafeMath.sol");
var DigitalShares = artifacts.require("./DigitalShares.sol");

module.exports = function(deployer) {
	deployer.deploy(SafeMath);
	deployer.link(SafeMath, DigitalShares);
	deployer.deploy(DigitalShares);
};
