pragma solidity ^0.8.0;

contract InterestRateModel {

  // Base interest rate (e.g., annual percentage yield)
  uint public baseRate;

  // Slope of the interest rate curve (determines how quickly rate increases with utilization)
  uint public slope;

  // Maximum borrow rate (e.g., a cap to prevent excessive borrowing)
  uint public maxRate;

  // Borrowing utilization ratio (total borrows / total deposits)
  function getUtilizationRatio(uint totalBorrows, uint totalDeposits) public view returns (uint) {
    if (totalDeposits == 0) return 0;
    return totalBorrows * 1e18 / totalDeposits; // Utilize 1e18 for fixed-point math
  }

  // Function to calculate the interest rate based on utilization ratio
  function getInterestRate(uint totalBorrows, uint totalDeposits) public view returns (uint) {
    uint utilizationRatio = getUtilizationRatio(totalBorrows, totalDeposits);
    uint interestRate = baseRate + utilizationRatio * slope;
    if (interestRate > maxRate) {
      interestRate = maxRate;
    }
    return interestRate;
  }

  // Constructor to set initial parameters (baseRate, slope, maxRate)
  constructor(uint _baseRate, uint _slope, uint _maxRate) {
    baseRate = _baseRate;
    slope = _slope;
    maxRate = _maxRate;
  }
}
