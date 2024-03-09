pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
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
    mapping(address => uint) public borrowAmounts;
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
        // Check if the borrower is overcollateralized
        require(
            collateralManager.canBorrow(msg.sender, amount),
            "Insufficient collateral"
        );

        // Update accounting (totalBorrows, etc.)
        totalBorrows += amount;

        // Transfer borrowed assets to the borrower
        IERC20(underlyingAsset).transfer(msg.sender, amount);

        // Update collateral in the CollateralManager
        collateralManager.updateCollateral(msg.sender, amount);
    }

    // Function to repay borrowed assets
    function repay(uint amount) public {
        // Transfer the repayment amount from the user to the contract
        IERC20(underlyingAsset).transferFrom(msg.sender, address(this), amount);

        // Update the user's borrow amount in the CollateralManager
        collateralManager.updateBorrowAmount(msg.sender, -int(amount));

        // Update the total borrows in the LendingPool
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

    function getUserBorrows(address borrower) public view returns (uint) {
        // Return the borrower's borrow amount from the borrowAmounts mapping
        return borrowAmounts[borrower];
    }

    // Simplified Liquidation Function (for demonstration purposes only)
    function liquidate(address borrower) public {
        // Check if borrower is undercollateralized with CollateralManager
        if (collateralManager.isUndercollateralized(borrower)) {
            // Seize a portion of the borrower's collateral (simplified logic)
            uint seizureRatio = 50; // Example seizure ratio of 50%
            uint seizedAmount = collateralManager.seizeCollateral(borrower, seizureRatio);
            // Sell seized collateral using external oracle or price feed (not implemented)
            // ... sell seized collateral and get liquidation proceeds ...
            // Transfer liquidation proceeds to the liquidator with a bonus (not implemented)
            liquidationManager.handleLiquidation(borrower, seizedAmount); // Call LiquidationManager for further actions
        }
    }
}
