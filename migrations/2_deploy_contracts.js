const ERC20Token = artifacts.require("ERC20Token");
const InterestRateModel = artifacts.require("InterestRateModel");
const CollateralManager = artifacts.require("CollateralManager");
const LiquidationManager = artifacts.require("LiquidationManager");
const LendingPool = artifacts.require("LendingPool");
const PriceOracle = artifacts.require("PriceOracle"); // Import the PriceOracle contract

module.exports = function(deployer) {
  deployer.deploy(ERC20Token, "Luna", "LUC").then(() => {
    return deployer.deploy(InterestRateModel, 100, 200, 50, 5000);
  }).then(() => {
    return deployer.deploy(CollateralManager, 15000);
  }).then(() => {
    return deployer.deploy(LiquidationManager, 500);
  }).then(() => {
    // Deploy the PriceOracle contract
    return deployer.deploy(PriceOracle);
  }).then(() => {
    return deployer.deploy(LendingPool, ERC20Token.address, InterestRateModel.address, CollateralManager.address, LiquidationManager.address); // Pass the PriceOracle address to LendingPool constructor
  });
};
