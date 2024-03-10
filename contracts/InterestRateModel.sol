// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract InterestRateModel {
    uint256 public baseRatePerYear; // Base interest rate per year (in basis points)
    uint256 public multiplierPerYear; // Multiplier per year (in basis points)
    uint256 public jumpMultiplierPerYear; // Jump multiplier per year (in basis points)
    uint256 public kink; // Utilization ratio at which the jump multiplier is applied (in basis points)

    constructor(
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear,
        uint256 _jumpMultiplierPerYear,
        uint256 _kink
    ) {
        baseRatePerYear = _baseRatePerYear;
        multiplierPerYear = _multiplierPerYear;
        jumpMultiplierPerYear = _jumpMultiplierPerYear;
        kink = _kink;
    }

    function getBorrowRate(uint256 utilizationRate) external view returns (uint256) { 
        if (utilizationRate < kink) {
            return baseRatePerYear + utilizationRate * multiplierPerYear / 1e4;
        } else {
            uint256 normalRate = baseRatePerYear + kink * multiplierPerYear / 1e4;
            uint256 excessUtilizationRate = utilizationRate - kink;
            return normalRate + excessUtilizationRate * jumpMultiplierPerYear / 1e4;
        }
    }
}
