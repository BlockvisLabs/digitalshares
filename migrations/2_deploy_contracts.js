// var SafeMath = artifacts.require("zeppelin/SafeMath.sol");
// var DigitalShares = artifacts.require("./DigitalShares.sol");

//module.exports = function(deployer) {
	// deployer.deploy(SafeMath);
	// deployer.link(SafeMath, DigitalShares);
	// deployer.deploy(DigitalShares, 10000);
//};


var RedBlackTreeLib = artifacts.require("./RedBlackTree.sol");
var TestRedBlackTree = artifacts.require("./TestRedBlackTree.sol");

module.exports = function(deployer) {
  deployer.deploy(RedBlackTreeLib);
  deployer.link(RedBlackTreeLib, TestRedBlackTree);
  deployer.deploy(TestRedBlackTree);
};
