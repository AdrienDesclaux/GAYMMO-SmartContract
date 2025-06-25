// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library AssetManagerMath {
    // Function to calculate the value of an asset based on its price and quantity
    // Adjusts for price feed decimals
    function calculateRentPrice(uint256 rentPerMonth, uint256 months) internal pure returns (uint256) {
        if (months == 0) {
            return 0;
        }
        return months * rentPerMonth * 10 ** 18;
    }

    function calculateAssetValue(
        uint256 pricePerToken,
        uint256 quantity,
        uint8 priceFeedDecimals
    ) internal pure returns (uint256) {
        if (quantity == 0 || pricePerToken == 0) {
            return 0;
        }
        return (pricePerToken * quantity) / (10 ** uint256(priceFeedDecimals));
    }
}
