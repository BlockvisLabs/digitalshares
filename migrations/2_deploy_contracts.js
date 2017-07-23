var SafeMath = artifacts.require("./SafeMath.sol");
var MyContract = artifacts.require("./MyContract.sol");

module.exports = function(deployer) {
	deployer.deploy(SafeMath);
	deployer.link(SafeMath, MyContract);
	deployer.deploy(MyContract);
};
