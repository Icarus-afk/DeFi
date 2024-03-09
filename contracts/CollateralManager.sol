// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CollateralManager {
    struct Position {
        uint256 collateralAmount;
        uint256 borrowedAmount;
    }

    mapping(address => mapping(address => Position)) public positions; // userAddress => tokenAddress => Position

    uint256 public collateralRatioThreshold; // Collateral ratio threshold (in basis points)

    constructor(uint256 _collateralRatioThreshold) {
        collateralRatioThreshold = _collateralRatioThreshold;
    }

    function depositCollateral(address token, uint256 amount) external {
        // Transfer collateral from user to contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Update user's position
        positions[msg.sender][token].collateralAmount += amount;
    }

    function withdrawCollateral(address token, uint256 amount) external {
        // Ensure user has enough collateral
        require(positions[msg.sender][token].collateralAmount >= amount, "Insufficient collateral");

        // Transfer collateral from contract to user
        IERC20(token).transfer(msg.sender, amount);

        // Update user's position
        positions[msg.sender][token].collateralAmount -= amount;
    }

    function calculateCollateralRatio(address user, address token) public view returns (uint256) {
        if (positions[user][token].borrowedAmount == 0) {
            return 1e4; // 100% collateral ratio if no borrowed amount
        }
        return positions[user][token].collateralAmount * 1e4 / positions[user][token].borrowedAmount;
    }

    function isCollateralSufficient(address user, address token) external view returns (bool) {
        uint256 collateralRatio = calculateCollateralRatio(user, token);
        return collateralRatio >= collateralRatioThreshold;
    }
}
