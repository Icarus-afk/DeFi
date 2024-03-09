pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PriceOracle.sol";
import "./LendingPool.sol";

contract CollateralManager is ReentrancyGuard {
    // Mapping of user addresses to their deposited collateral (ERC20 token address -> amount)
    mapping(address => mapping(address => uint)) public collateral;

    // Minimum collateral ratio (e.g., 1.5 means 1.5x collateral value compared to borrow amount)
    uint public minRatio;

    // Address of the PriceOracle contract
    address public priceOracle;

    // Address of the LendingPool contract
    address public lendingPool;

    mapping(address => uint) public borrowAmounts;

    constructor(uint _minRatio, address _priceOracle, address _lendingPool) {
        minRatio = _minRatio;
        priceOracle = _priceOracle;
        lendingPool = _lendingPool;
    }

    function max(uint a, uint b) public pure returns (uint) {
        return a >= b ? a : b;
    }

    // Function for borrowers to deposit collateral (specific ERC20 token)
    function deposit(
        address borrower,
        address token,
        uint amount
    ) public nonReentrant {
        collateral[borrower][token] += amount;
    }

    // Function for borrowers to withdraw collateral (specific ERC20 token)
    function withdraw(
        address borrower,
        address token,
        uint amount
    ) public nonReentrant {
        require(
            collateral[borrower][token] >= amount,
            "Insufficient collateral balance"
        );
        collateral[borrower][token] -= amount;
    }

    function canBorrow(
        address borrower,
        uint amount
    ) public view returns (bool) {
        uint totalCollateralValue = 0;
        address[] memory tokens = getCollateralTokens(borrower);
        for (uint i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            uint price = PriceOracle(priceOracle).getPrice(tokenAddress);
            totalCollateralValue += collateral[borrower][tokenAddress] * price;
        }

        return totalCollateralValue >= (amount * minRatio);
    }

    // Function to check if a borrower is undercollateralized for a specific loan
    function isUndercollateralized(
        address borrower
    ) public view returns (bool) {
        // Calculate total collateral value based on price oracle
        uint totalCollateralValue = 0;
        address[] memory tokens = getCollateralTokens(borrower);
        for (uint i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            uint price = PriceOracle(priceOracle).getPrice(tokenAddress);
            totalCollateralValue += collateral[borrower][tokenAddress] * price;
        }

        // Integration with LendingPool contract
        uint borrowAmount = LendingPool(lendingPool).getUserBorrows(borrower);
        return totalCollateralValue < borrowAmount * minRatio;
    }

    // Function to seize a portion of collateral during liquidation
    function seizeCollateral(
        address borrower,
        uint seizureRatio
    ) public nonReentrant returns (uint) {
        require(
            seizureRatio > 0 && seizureRatio <= 100,
            "Invalid seizure ratio"
        );
        uint totalSeized = 0;
        address[] memory tokens = getCollateralTokens(borrower);
        for (uint i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            uint balance = collateral[borrower][tokenAddress];
            uint seizedAmount = (balance * seizureRatio) / 100;
            collateral[borrower][tokenAddress] -= seizedAmount;
            totalSeized += seizedAmount;
        }
        return totalSeized;
    }

    // Fixed getCollateralTokens function:
    function getCollateralTokens(
        address borrower
    ) public view returns (address[] memory) {
        uint counter = 0;
        address payable borrowerAddress = payable(
            address(uint160(uint256(keccak256(abi.encodePacked(borrower)))))
        );

        // Loop through each token address in the current borrower's mapping

        // Iterate through each key-value pair in the borrower's collateral mapping
        for (
            address tokenAddress = keccak256(abi.encodePacked(borrower));
            tokenAddress <
            keccak256(
                abi.encodePacked(
                    borrower,
                    uint256(
                        max(
                            type(uint256).max,
                            collateral[borrower][tokenAddress]
                        )
                    )
                )
            );
            tokenAddress = keccak256(abi.encodePacked(tokenAddress))
        ) {
            // Check if the balance for the current token is greater than 0
            if (collateral[borrower][tokenAddress] > 0) {
                counter++;
            }
        }
        // Allocate memory for the return array based on the number of non-zero balances
        address[] memory tokens = new address[](counter);
        counter = 0;
        for (
            address tokenAddress = address(
                uint160(uint256(keccak256(abi.encodePacked(borrower))))
            );
            tokenAddress <
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                borrower,
                                uint256(
                                    max(collateral.length, type(uint256).max)
                                )
                            )
                        )
                    )
                )
            );
            tokenAddress = address(
                uint160(uint256(keccak256(abi.encodePacked(tokenAddress))))
            )
        ) {
            if (collateral[borrower][tokenAddress] > 0) {
                tokens[counter] = tokenAddress;
                counter++;
            }
        }
        return tokens;
    }

    // Function to get the total collateral value in a specific token (for informational purposes)
    function getCollateralValueInToken(
        address borrower,
        address token
    ) public view returns (uint) {
        uint price = PriceOracle(priceOracle).getPrice(token);
        return collateral[borrower][token] * price;
    }

    // Function to update the borrower's collateral after a borrow operation
    function updateCollateral(address borrower, uint borrowAmount) public {
        require(
            msg.sender == lendingPool,
            "Only the LendingPool contract can update collateral"
        );

        // Calculate the required collateral based on the minimum ratio
        uint requiredCollateral = borrowAmount * minRatio;

        // Iterate over the borrower's collateral tokens
        address[] memory tokens = getCollateralTokens(borrower);
        uint currentCollateralValue = 0;
        for (uint i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            uint price = PriceOracle(priceOracle).getPrice(tokenAddress);
            currentCollateralValue +=
                collateral[borrower][tokenAddress] *
                price;
        }

        // If the current collateral value is less than the required collateral, reduce the collateral
        if (currentCollateralValue < requiredCollateral) {
            uint collateralToReduce = requiredCollateral -
                currentCollateralValue;
            for (uint i = 0; i < tokens.length; i++) {
                address tokenAddress = tokens[i];
                uint price = PriceOracle(priceOracle).getPrice(tokenAddress);
                uint tokenCollateral = collateral[borrower][tokenAddress];
                uint tokenCollateralValue = tokenCollateral * price;

                if (tokenCollateralValue > 0) {
                    uint reductionAmount = (collateralToReduce *
                        tokenCollateralValue) / currentCollateralValue;
                    if (reductionAmount > tokenCollateral) {
                        collateral[borrower][tokenAddress] = 0;
                        collateralToReduce -= tokenCollateralValue;
                    } else {
                        collateral[borrower][tokenAddress] -= reductionAmount;
                        break;
                    }
                }
            }
        }
    }

    function updateBorrowAmount(address borrower, int amountDelta) public {
        require(
            msg.sender == lendingPool,
            "Only the LendingPool contract can update borrow amounts"
        );

        // Update the borrower's borrow amount
        borrowAmounts[borrower] = borrowAmounts[borrower] + uint(amountDelta);
        address[] memory tokens = getCollateralTokens(borrower);
        // Adjust the borrower's collateral based on the new borrow amount
        uint newBorrowAmount = borrowAmounts[borrower];
        uint requiredCollateral = newBorrowAmount * minRatio;
        uint currentCollateralValue = getCurrentCollateralValue(borrower);

        // Similar logic as in updateCollateral function
        if (currentCollateralValue < requiredCollateral) {
            uint collateralToReduce = requiredCollateral -
                currentCollateralValue;
            for (uint i = 0; i < tokens.length; i++) {
                address tokenAddress = tokens[i];
                uint price = PriceOracle(priceOracle).getPrice(tokenAddress);
                uint tokenCollateral = collateral[borrower][tokenAddress];
                uint tokenCollateralValue = tokenCollateral * price;

                if (tokenCollateralValue > 0) {
                    uint reductionAmount = (collateralToReduce *
                        tokenCollateralValue) / currentCollateralValue;
                    if (reductionAmount > tokenCollateral) {
                        collateral[borrower][tokenAddress] = 0;
                        collateralToReduce -= tokenCollateralValue;
                    } else {
                        collateral[borrower][tokenAddress] -= reductionAmount;
                        break;
                    }
                }
            }
        }
    }

    function getCurrentCollateralValue(
        address borrower
    ) public view returns (uint) {
        uint totalCollateralValue = 0;
        address[] memory tokens = getCollateralTokens(borrower);
        for (uint i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            uint price = PriceOracle(priceOracle).getPrice(tokenAddress);
            totalCollateralValue += collateral[borrower][tokenAddress] * price;
        }
        return totalCollateralValue;
    }
}
