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

    function calculateAssetValue(uint256 pricePerUnit, uint256 quantity) internal pure returns (uint256) {
        if (quantity == 0) {
            return 0;
        }
        return pricePerUnit * quantity;
    } 
}
