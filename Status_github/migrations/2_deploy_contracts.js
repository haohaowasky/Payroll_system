var PayrollInterface = artifacts.require("PayrollInterface.sol")
module.exports = function(deployer) {
  deployer.deploy(PayrollInterface);
  //deployer.autolink(); // for linking imports of other contracts
};

var SafeMath = artifacts.require("SafeMath.sol")
module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  //deployer.autolink(); // for linking imports of other contracts
};

var ERC223 = artifacts.require("ERC223.sol")
module.exports = function(deployer) {
  deployer.deploy(ERC223);
  //deployer.autolink(); // for linking imports of other contracts
};

var ERC20 = artifacts.require("ERC20.sol")
module.exports = function(deployer) {
  deployer.deploy(ERC20);
  //deployer.autolink(); // for linking imports of other contracts
};
