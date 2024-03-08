pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./InterestRateModel.sol";
import "./CollateralManager.sol";
import "./LiquidationManager.sol";

contract LendingPool is ReentrancyGuard {

  address public underlyingAsset; // Address of the deposited asset (ETH or ERC-20 token)
  InterestRateModel public interestRateModel;
  CollateralManager public collateralManager;
  LiquidationManager public liquidationManager;

  // Mapping of user addresses to their deposited asset amount
  mapping(address => uint) public deposits;

  // Total amount of assets deposited in the pool
  uint public totalDeposits;

  // Total amount of assets borrowed from the pool
  uint public totalBorrows;

  constructor(
    address _underlyingAsset,
    address _interestRateModel,
    address _collateralManager,
    address _liquidationManager
  ) {
    underlyingAsset = _underlyingAsset;
    interestRateModel = InterestRateModel(_interestRateModel);
    collateralManager = CollateralManager(_collateralManager);
    liquidationManager = LiquidationManager(_liquidationManager);
  }

  // Function to deposit assets into the pool (with ReentrancyGuard)
  function deposit(uint amount) public nonReentrant {
    IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);
    deposits[msg.sender] += amount;
    totalDeposits += amount;
  }

  // Function to withdraw deposited assets
  function withdraw(uint amount) public {
    require(deposits[msg.sender] >= amount, "Insufficient balance");
    IERC20(underlyingAsset).transfer(msg.sender, amount);
    deposits[msg.sender] -= amount;
    totalDeposits -= amount;
  }

  // Function to borrow assets by providing collateral
  function borrow(uint amount) public {
    // Check collateralization requirements and borrow amount based on InterestRateModel and CollateralManager
    collateralManager.borrow(msg.sender, amount, interestRateModel.getInterestRate(totalBorrows, totalDeposits));
    totalBorrows += amount;
    // Transfer borrowed assets to the borrower
    IERC20(underlyingAsset).transfer(msg.sender, amount);
  }

  // Function to repay borrowed assets
  function repay(uint amount) public {
    IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);
    collateralManager.repay(msg.sender, amount);
    totalBorrows -= amount;
  }

  // Function to calculate the current interest rate
  function getInterestRate() public view returns (uint) {
    return interestRateModel.getInterestRate(totalBorrows, totalDeposits);
  }

  // Function to accrue interest (logic not implemented for brevity)
  function accrueInterest() public {
    // Implement logic to calculate accrued interest based on interest rate and time
    // Update totalBorrows and deposits accordingly
  }

  // Simplified Liquidation Function (for demonstration purposes only)
  function liquidate(address borrower) public {
    // Check if borrower is undercollateralized with CollateralManager
    if (collateralManager.isUndercollateralized(borrower)) {
      // Seize a portion of the borrower's collateral (simplified logic)
      uint seizedAmount = collateralManager.seizeCollateral(borrower);
      // Sell seized collateral using external oracle or price feed (not implemented)
      // ... sell seized collateral and get liquidation proceeds ...
      // Transfer liquidation proceeds to the liquidator with a bonus (not implemented)
      liquidationManager.handleLiquidation(borrower, seizedAmount); // Call LiquidationManager for further actions
    }
  }
}
