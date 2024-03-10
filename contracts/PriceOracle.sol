// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// Interface for interacting with a decentralized oracle provider
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            int256 roundId,
            int256 answer,
            int256 startedAt,
            int256 updatedAt,
            int8 answeredInRound
        );
}

contract PriceOracle {
    // Mapping to store asset addresses and their corresponding Chainlink aggregator contracts
    mapping(address => address) public assetToAggregator;

    // Function to set the Chainlink aggregator address for an asset
    function setAggregator(address asset, address aggregator) public {
        assetToAggregator[asset] = aggregator;
    }

    // Function to fetch the price of an asset from Chainlink
    function getPrice(address asset) public view returns (uint256) {
        require(
            assetToAggregator[asset] != address(0),
            "No aggregator set for this asset"
        );
        AggregatorV3Interface aggregator = AggregatorV3Interface(
            assetToAggregator[asset]
        );
        (
            int256 roundId,
            int256 answer,
            int256 startedAt,
            int256 updatedAt,
            int8 answeredInRound
        ) = aggregator.latestRoundData();
        require(answer > 0, "Invalid price data from oracle");
        return uint256(answer);
    }
}
