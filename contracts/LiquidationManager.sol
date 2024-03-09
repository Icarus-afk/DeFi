pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LendingPool.sol";

contract LiquidationManager {

  // Address of the LendingPool contract
  address public lendingPool;

  // Liquidation bonus percentage awarded to liquidators (e.g., 5%)
  uint public liquidationBonus;

  constructor(address _lendingPool, uint _liquidationBonus) {
    lendingPool = _lendingPool;
    liquidationBonus = _liquidationBonus;
  }

  // Function called by LendingPool during liquidation
  function handleLiquidation(address borrower, uint seizedAmount) public {
    // Sell seized collateral using an external oracle or AMM (not implemented)
    // ... sell seized collateral and get liquidation proceeds ...
    // Calculate liquidation bonus and remaining proceeds
    uint bonus = seizedAmount * liquidationBonus / 100;
    uint remainingProceeds = seizedAmount - bonus;
    // Pay seized collateral proceeds (minus bonus) to the borrower's debt in LendingPool
    IERC20(LendingPool(lendingPool).underlyingAsset()).transfer(lendingPool, remainingProceeds);
    // Transfer liquidation bonus to the liquidator
    IERC20(LendingPool(lendingPool).underlyingAsset()).transfer(msg.sender, bonus);
  }
}
