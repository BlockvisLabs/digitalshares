var SafeMath = artifacts.require("./SafeMath.sol");
var DigitalShares = artifacts.require("./DigitalShares.sol");
var OwnerHolder = artifacts.require("./OwnerHolder.sol");
var ShareSnapshot = artifacts.require("./ShareSnapshot.sol");

module.exports = function(deployer) {
	deployer.deploy(SafeMath);
	deployer.link(SafeMath, DigitalShares);
	deployer.deploy([OwnerHolder, ShareSnapshot, DigitalShares]);
};
