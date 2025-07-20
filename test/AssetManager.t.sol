// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
    address public treasury = address(0x789);

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

    function testClaimRentEth() public {
        // Déploiement et récupération
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setRentUsdPerMonth(1000);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        vm.stopPrank();
        vm.deal(user, 1 ether);

        // Achat de 10 tokens à 100 USD chacun (donc 0.05 ETH/token à 2000$/ETH)
        uint256 investmentAmount = 10;
        uint256 pricePerToken = AssetManager(assetManagerAddress).getLastPriceToken(eth); 
        uint256 totalCost = pricePerToken * investmentAmount;

        vm.startPrank(user);
        assetManager.buyAssetTokenWithETH{value: totalCost}(investmentAmount);
        vm.stopPrank();

        // Balance avant le claim
        uint256 balanceBefore = user.balance;


        uint256 timeToAdvance = 30 days;
        vm.warp(block.timestamp + timeToAdvance);

        vm.deal(address(assetManager), 10000 ether);
        // Claim des loyers
        vm.startPrank(user);
        assetManager.claimRent(eth);
        vm.stopPrank();

        uint256 balanceAfter = user.balance;

        // Vérification que des loyers ont été envoyés (ETH reçu > 0)
        assertGt(balanceAfter, balanceBefore);

        // Vérification que le timestamp de dernier claim est bien mis à jour
        uint256 lastClaim = assetManager.getLastClaimed(user);
        assertEq(lastClaim, block.timestamp);
    }

    function testClaimRentUSDT() public {
        // Déploiement et récupération
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setRentUsdPerMonth(1000);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        vm.stopPrank();
        vm.deal(user, 10000 ether);

        // Achat de 10 tokens à 100 USD chacun (donc 0.05 ETH/token à 2000$/ETH)
        uint256 investmentAmount = 10;
        uint256 pricePerToken = AssetManager(assetManagerAddress).getLastPriceToken(eth); 
        uint256 totalCost = pricePerToken * investmentAmount;

        vm.startPrank(user);
        assetManager.buyAssetTokenWithETH{value: totalCost}(investmentAmount);
        vm.stopPrank();

        // Balance avant le claim
        uint256 balanceBefore = user.balance;

        uint256 timeToAdvance = 30 days;
        vm.warp(block.timestamp + timeToAdvance);

        // Claim des loyers
        vm.startPrank(user);
        assetManager.claimRent(eth);
        vm.stopPrank();

        uint256 balanceAfter = user.balance;

        // Vérification que des loyers ont été envoyés (ETH reçu > 0)
        assertGt(balanceAfter, balanceBefore);

        // Vérification que le timestamp de dernier claim est bien mis à jour
        uint256 lastClaim = assetManager.getLastClaimed(user);
        assertEq(lastClaim, block.timestamp);
    }

    function testSetAvailableSupply() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setAvailableSupply(10000 * 10 ** 18);
        vm.stopPrank();

        assertEq(assetManager.getAvailableSupply(), 10000 * 10 ** 18);
    }

    function testSetRentUsdPerMonth() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setRentUsdPerMonth(500);
        vm.stopPrank();

        assertEq(assetManager.getRentUsdPerMonth(), 500);
    }
    function testClaimRentEthWithinvalidTimeStamp() public {
        // Déploiement et récupération
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setRentUsdPerMonth(1000);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        vm.stopPrank();
        vm.deal(user, 1 ether);

        uint256 investmentAmount = 10;
        uint256 pricePerToken = AssetManager(assetManagerAddress).getLastPriceToken(eth); 
        uint256 totalCost = pricePerToken * investmentAmount;

        vm.startPrank(user);
        assetManager.buyAssetTokenWithETH{value: totalCost}(investmentAmount);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidTimestamp.selector));
        assetManager.claimRent(eth);
        vm.stopPrank();

    }

    function testSetPriceFeedWithInvalidPriceFeedAddress() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidFeedTokenAddress.selector));
        assetManager.setPriceFeed(eth, address(0));
        vm.stopPrank();
    }

    function testSetPriceFeedWithInvalidToken() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidAssetTokenAddress.selector));
        assetManager.setPriceFeed(address(0), address(mockEthUsdFeed));
        vm.stopPrank();
    }

    function testGetLastPriceTokenWithInvalidFeed() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.FeedTokenNotFound.selector));
        assetManager.getLastPriceToken(eth);
        vm.stopPrank();
    }

    function testGetLastPriceTokenWithInvalidPrice() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        vm.stopPrank();

        // Simulate a price feed with no data
        MockV3Aggregator mockAggregator = new MockV3Aggregator(8, 0);
        vm.startPrank(owner);
        assetManager.setPriceFeed(eth, address(mockAggregator));
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidPrice.selector));
        assetManager.getLastPriceToken(eth);
        vm.stopPrank();
    }

    function testSetRentPriceWithInvalidRent() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
            vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidPrice.selector));
            assetManager.setRentUsdPerMonth(0);
        vm.stopPrank();
    }

    function testCalculateRentPriceWithInvalidRent() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
            vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidPrice.selector));
            assetManager.calculateRentPrice();
        vm.stopPrank();
    }

    function testBuyAssetTokenWithInvalidAmount() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        assetManager.setAvailableSupply(15000 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidAmount.selector));
        assetManager.buyAssetTokenWithETH{value: 0}(0);
        vm.stopPrank();
    }

    function testBuyAssetTokenWithExceedingSupply() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setPriceFeed(eth, address(mockEthUsdFeed));
        assetManager.setAvailableSupply(100 * 10 ** 18);
        vm.stopPrank();

        uint256 amountToBuy = 200 * 10 ** 18; 
        uint256 pricePerToken = assetManager.getLastPriceToken(eth); 
        uint256 totalPrice = amountToBuy * pricePerToken / 10 ** 18;

        vm.deal(user, totalPrice); // Give user enough ETH

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.LimitExceeded.selector));
        assetManager.buyAssetTokenWithETH{value: totalPrice}(amountToBuy);
        vm.stopPrank();
    }

    function testInitializeWithBadAsset() public {
        // Attempt to initialize AssetManager with an invalid asset address
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidAssetAddress.selector));
        AssetManager(assetManagerImpl).initialize(address(0), address(assetTokenImpl), 1, owner);
        vm.stopPrank();
    }
    function testInitializeWithBadAssetToken() public {
        // Attempt to initialize AssetManager with an invalid asset token address
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidAssetTokenAddress.selector));
        AssetManager(assetManagerImpl).initialize(createdAssetAddress1, address(0), 1, owner);
        vm.stopPrank();
    }
    function testInitializeWithBadUsdPrice() public {
        address assetAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        address assetTokenAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetTokenAddress;
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidPrice.selector));
        AssetManager(assetManagerImpl).initialize(assetAddress, assetTokenAddress, 0, owner);
        vm.stopPrank();
    }

    function testGetUsdPricePerToken() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setUsdPricePerToken(10); 
        vm.stopPrank();

        uint256 pricePerToken = assetManager.getUsdPricePerToken();
        uint256 expectedPrice = 10 * 10 ** 18; 
        assertEq(pricePerToken, expectedPrice);
    }

    function testSetUsdPricePerTokenWithInvalidPrice() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidPrice.selector));
        assetManager.setUsdPricePerToken(0);
        vm.stopPrank();
    }

    function testGetLastInvestments() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

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

        AssetManager.LastsInvestment[] memory lastInvestments = assetManager.getLastsInvestment(user);
        
        assertEq(lastInvestments[0].amount, amountToBuy);
        assertEq(lastInvestments[0].timestamp, block.timestamp);
    }

    function testGetTreasury() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setTreasuryAddress(treasury);
        vm.stopPrank();

        assertEq(assetManager.getTreasuryAddress(), treasury);
    }

    function testSetTreasuryWithInvalidAddress() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidTreasuryAddress.selector));
        assetManager.setTreasuryAddress(address(0));
        vm.stopPrank();
    }
    
    function testCalculateAssetValue() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setUsdPricePerToken(10);
        vm.stopPrank();

        uint256 totalSupply = 1000 * 10 ** 18;
        uint256 expectedValue = totalSupply * assetManager.getUsdPricePerToken(); // 10 USD per token, converted to wei

        assertEq(assetManager.calculateAssetValue(totalSupply), expectedValue);
    }

    function testCalculateAssetValueWithZeroSupply() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setUsdPricePerToken(10);
        vm.stopPrank();
        
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidAmount.selector));
        assetManager.calculateAssetValue(0);
        vm.stopPrank();
    }

    function testSetTreasuryAddress() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.startPrank(owner);
        assetManager.setTreasuryAddress(treasury);
        vm.stopPrank();

        assertEq(assetManager.getTreasuryAddress(), treasury);
    }

    /*function testBuyAssetTokenAndVerifyTreasuryAddress() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);

        vm.deal(owner, 10 ether); 
        vm.startPrank(owner);
        assetManager.setTreasuryAddress(treasury);
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

        assertEq(assetManager.getTreasuryAddress(), treasury);

        //Need to create a mock for the treasury to test this
    }*/

    function testClaimRentWithInvalidPrice() public {
        address assetManagerAddress = assetFactory.getAssetDetails(createdAssetAddress1).assetManagerAddress;
        AssetManager assetManager = AssetManager(assetManagerAddress);
 
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

        uint256 newTimestamp = block.timestamp + 30 days;

        vm.warp(newTimestamp);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(AssetManager.InvalidPrice.selector));
        assetManager.claimRent(eth);
        vm.stopPrank();
    }
}