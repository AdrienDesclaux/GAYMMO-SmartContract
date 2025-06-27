// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {AssetFactory} from "../src/AssetFactory.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {AssetManager} from "../src/AssetManager.sol";
import {Asset} from "../src/Asset.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";


contract AssetManagerTest is Test {
    AssetFactory private assetFactory;
    AssetToken private assetTokenImpl;
    AssetManager private assetManagerImpl;
    Asset private assetImpl;
    address createdAssetAddress1;
    address createdAssetAddress2;
    MockV3Aggregator private mockEthUsdFeed;
    address private eth = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);


    address private owner = address(0x123);
    address private user = address(0x456);
    address private treasury = address(0x789);

    function setUp() public {
        // Deploy implementations (templates)
        vm.startPrank(owner);
        assetTokenImpl = new AssetToken();
        assetImpl = new Asset();
        assetManagerImpl = new AssetManager();
        vm.stopPrank();

        // Create the factory with the implementations
        assetFactory = new AssetFactory(address(assetImpl), address(assetTokenImpl), address(assetManagerImpl));
        
        // Create an asset to test the AssetManager
        vm.startPrank(owner);
            createdAssetAddress1 = assetFactory.createAsset("Test Asset", "TAST", owner);
            createdAssetAddress2 = assetFactory.createAsset("Test Asset 2", "TAST2", owner);
            mockEthUsdFeed = new MockV3Aggregator(8, 2000 * 10 ** 8);
        vm.stopPrank();
    }

    function testSetPriceFeed() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        vm.stopPrank();

        assertEq(assetManager.getLastPriceToken(eth), 5 * 10 ** 14);
    }

    function testbuyAssetTokenWithETH() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);
        address assetTokenAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetTokenAddress;
        AssetToken assetToken = AssetToken(assetTokenAddress);

        vm.startPrank(owner);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        assetManager.setAvailableSupply(15000 * 10 ** 18);
        vm.stopPrank();

        uint256 amountToBuy = 100 * 10 ** 18;
        uint256 pricePerToken = assetManager.getLastPriceToken(eth); 
        uint256 totalPrice = amountToBuy * pricePerToken / 10 ** 18;

        vm.deal(user, totalPrice);

        vm.startPrank(user);
        assetManager.buyAssetTokenWithETH{value: totalPrice}(amountToBuy);
        vm.stopPrank();

        assertEq(assetToken.balanceOf(user), amountToBuy);
    }

    function testCalculateRentPrice() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setRentUsdPerMonth(100); // Set rent to $100 per month
        vm.stopPrank();

        uint256 rentUsdPerMonth = assetManager.getRentUsdPerMonth();
        uint256 rentPrice = assetManager.calculateRentPrice();
        uint256 expectedRentPrice = (rentUsdPerMonth * 12 * 10 ** 18 ) / (365 days + 6 hours);

        assertEq(rentPrice, expectedRentPrice);
    }
}