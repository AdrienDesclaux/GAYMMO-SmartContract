// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { AssetManagerMath } from "../utils/AssetManagerMath.sol";

contract AssetManagerMathTest is Test {
    using AssetManagerMath for uint256;

    function testCalculateAssetValue() public pure {
        uint256 assetPrice = 1000; // Price per asset
        uint256 assetQuantity = 10; // Number of assets

        uint256 expectedValue = assetPrice * assetQuantity;
        uint256 calculatedValue = assetPrice.calculateAssetValue(assetQuantity);

        assertEq(calculatedValue, expectedValue, "Asset value calculation failed");
    }

    function testCalculateSecondsRentPriceWithZeroRent() public pure {
        uint256 rentPerMonth = 0; // Rent per month

        uint256 expectedSecondsRentPrice = 0;
        uint256 calculatedSecondsRentPrice = rentPerMonth.calculateSecondsRentPrice();

        assertEq(calculatedSecondsRentPrice, expectedSecondsRentPrice);
    }

}