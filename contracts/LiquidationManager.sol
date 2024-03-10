// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidationManager {
    address public owner;
    uint256 public liquidationBonus; // Liquidation bonus percentage (in basis points)

    constructor(uint256 _liquidationBonus) {
        owner = msg.sender;
        liquidationBonus = _liquidationBonus;
    }

    function setLiquidationBonus(uint256 _liquidationBonus) external {
        require(msg.sender == owner, "Only owner can set liquidation bonus");
        liquidationBonus = _liquidationBonus;
    }

    function liquidatePosition(address borrower, address collateralToken, address borrowedToken, uint256 borrowedAmount) external {
        // TODO: Implement liquidation logic
        // For now, we'll assume liquidation is successful and transfer assets accordingly

        // Calculate liquidation amount
        uint256 liquidationAmount = borrowedAmount * (1e4 + liquidationBonus) / 1e4;

        // Transfer collateral tokens to liquidator
        IERC20(collateralToken).transfer(msg.sender, liquidationAmount);

        // Transfer borrowed tokens from liquidator to borrower
        IERC20(borrowedToken).transferFrom(msg.sender, borrower, borrowedAmount);

        // Reset borrower's position
        // For simplicity, we'll set collateral and borrowed amounts to zero
        // In a real implementation, you'd likely update the borrower's position in CollateralManager.sol
    }
}
