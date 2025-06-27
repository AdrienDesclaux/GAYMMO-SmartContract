// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library AssetManagerMath {
    // Function to calculate the value of an asset based on its price and quantity
    // Adjusts for price feed decimals
    function calculateAnnualRentPrice(uint256 rentPerMonth) internal pure returns (uint256) {
        return   12 * rentPerMonth * 10 ** 18;
    }

    function calculateSecondsRentPrice(uint256 rentPerMonth) internal pure returns (uint256) {
        if (rentPerMonth == 0) {
            return 0;
        }
        uint256 annualRent = calculateAnnualRentPrice(rentPerMonth);
        uint256 secondsInYear = calculateSecondsInYear();
        return (annualRent) /  secondsInYear;
    }

    function calculateTotalClaimRent(
        uint256 rentPerMonth,
        uint256 differenceTime
    ) internal pure returns (uint256) {
        uint256 secondsRent = calculateSecondsRentPrice(rentPerMonth);
        return (differenceTime * secondsRent) / 10 ** 18;
    }

    function calculateAssetValue(uint256 pricePerUnit, uint256 quantity) internal pure returns (uint256) {
        if (quantity == 0) {
            return 0;
        }
        return pricePerUnit * quantity;
    } 

    function calculateSecondsInYear() internal pure returns (uint256) {
        return 365 days + 6 hours;
    }
}
