// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20Token.sol";
import "./InterestRateModel.sol";
import "./CollateralManager.sol";
import "./LiquidationManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    ERC20Token public assetToken;
    InterestRateModel public interestRateModel;
    CollateralManager public collateralManager;
    LiquidationManager public liquidationManager;

    mapping(address => uint256) public borrowerDebt; // borrower address => total borrowed amount
    mapping(address => uint256) public lenderBalance; // lender address => total deposited amount

    constructor(
        ERC20Token _assetToken,
        InterestRateModel _interestRateModel,
        CollateralManager _collateralManager,
        LiquidationManager _liquidationManager
    ) {
        assetToken = _assetToken;
        interestRateModel = _interestRateModel;
        collateralManager = _collateralManager;
        liquidationManager = _liquidationManager;
    }

    function deposit(uint256 amount) external {
        assetToken.transferFrom(msg.sender, address(this), amount);
        lenderBalance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(lenderBalance[msg.sender] >= amount, "Insufficient balance");
        lenderBalance[msg.sender] -= amount;
        assetToken.transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        uint256 borrowRate = interestRateModel.getBorrowRate(getUtilizationRate());
        uint256 interest = (amount * borrowRate) / 1e4;
        uint256 totalAmount = amount + interest;

        require(collateralManager.isCollateralSufficient(msg.sender, address(assetToken)), "Insufficient collateral");

        // Ensure lender has enough balance
        require(lenderBalance[address(this)] >= totalAmount, "Not enough liquidity");

        // Transfer borrowed amount to borrower
        assetToken.transfer(msg.sender, amount);

        // Update borrower's debt
        borrowerDebt[msg.sender] += totalAmount;
    }

    function repay(uint256 amount) external {
        require(borrowerDebt[msg.sender] >= amount, "Amount exceeds debt");

        // Transfer repaid amount from borrower to contract
        assetToken.transferFrom(msg.sender, address(this), amount);

        // Update borrower's debt
        borrowerDebt[msg.sender] -= amount;
    }

    function liquidate(address borrower) external {
        require(!collateralManager.isCollateralSufficient(borrower, address(assetToken)), "Borrower is not undercollateralized");

        uint256 borrowedAmount = borrowerDebt[borrower];
        uint256 liquidationBonus = liquidationManager.liquidationBonus();
        uint256 liquidationAmount = (borrowedAmount * (1e4 + liquidationBonus)) / 1e4;

        // Transfer collateral tokens to liquidator
        assetToken.transfer(msg.sender, liquidationAmount);

        // Transfer borrowed tokens from liquidator to borrower
        assetToken.transferFrom(msg.sender, borrower, borrowedAmount);

        // Reset borrower's debt
        borrowerDebt[borrower] = 0;
    }

    function calculateBorrowRate(uint256 utilizationRate) external view returns (uint256) {
        return interestRateModel.getBorrowRate(utilizationRate);
    }

    function getUtilizationRate() public view returns (uint256) {
        return (totalBorrowed() * 1e4) / totalSupplied();
    }

    function totalSupplied() public view returns (uint256) {
        return assetToken.balanceOf(address(this));
    }

    function totalBorrowed() public view returns (uint256) {
        return totalSupplied() - assetToken.balanceOf(address(this));
    }
}
