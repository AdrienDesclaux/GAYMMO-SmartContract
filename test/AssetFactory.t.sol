// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {AssetFactory} from "../src/AssetFactory.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {AssetManager} from "../src/AssetManager.sol";
import {Asset} from "../src/Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AssetFactoryTest is Test {
    AssetFactory private assetFactory;
    AssetToken private assetTokenImpl;
    AssetManager private assetManagerImpl;
    Asset private assetImpl;

    address private owner = address(0x123);
    address private user = address(0x456);

    function setUp() public {
        // Déploiement des implémentations (templates)
        vm.startPrank(owner);
        assetTokenImpl = new AssetToken();
        assetImpl = new Asset();
        assetManagerImpl = new AssetManager();
        vm.stopPrank();

        // Création de la factory avec les implémentations
        assetFactory = new AssetFactory(address(assetImpl), address(assetTokenImpl), address(assetManagerImpl));
    }

    function testCreateAsset() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";

        vm.startPrank(owner);
        address createdAssetAddress = assetFactory.createAsset(name, symbol, owner);
        vm.stopPrank();
        
        // Cast de l'adresse clonée vers le type Asset
        Asset createdAsset = Asset(createdAssetAddress);

        // Vérifications
        assertEq(createdAsset.name(), name);
        assertEq(createdAsset.symbol(), symbol);
        assertEq(assetFactory.getAssetCount(), 1);
    }

    function testCreateAssetWithInvalidNameOrSymbol() public {
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(AssetFactory.EmptyName.selector));
        assetFactory.createAsset("", "TAST", owner);
        vm.expectRevert(abi.encodeWithSelector(AssetFactory.EmptySymbol.selector));
        assetFactory.createAsset("Test Asset", "", owner);
        vm.stopPrank();
    }

    function testCreateAssetWithExistingName() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";

        vm.startPrank(owner);
        assetFactory.createAsset(name, symbol, owner);

        vm.expectRevert(abi.encodeWithSelector(AssetFactory.AssetAlreadyExists.selector));
        assetFactory.createAsset(name, "TAST2", owner);
        vm.stopPrank();
    }

    function testGetAssetDetails() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";

        vm.startPrank(owner);
        address createdAssetAddress = assetFactory.createAsset(name, symbol, owner);
        vm.stopPrank();

        AssetFactory.Assets memory assetDetails  = assetFactory.getAssetDetails(createdAssetAddress);

        assertEq(Asset(assetDetails.assetAddress).name(), name);
        assertEq(AssetToken(assetDetails.assetTokenAddress).symbol(), symbol);
        assertTrue(assetDetails.assetManagerAddress != address(0));
        assertTrue(assetDetails.owner != address(0));
        assertEq(assetDetails.owner, owner);
    }

    function testGetAssets() public {
        string memory name1 = "Test Asset 1";
        string memory symbol1 = "TAST1";
        string memory name2 = "Test Asset 2";
        string memory symbol2 = "TAST2";

        vm.startPrank(owner);
        assetFactory.createAsset(name1, symbol1, owner);
        assetFactory.createAsset(name2, symbol2, owner);
        vm.stopPrank();

        address[] memory assets = assetFactory.getAssets();
        assertEq(assets.length, 2);
    }

    function testIsAsset() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";

        vm.startPrank(owner);
        address createdAssetAddress = assetFactory.createAsset(name, symbol, owner);
        vm.stopPrank();

        assertTrue(assetFactory.isAsset(createdAssetAddress));
        assertFalse(assetFactory.isAsset(address(0x789)));
    }

    function testAssetAlreadyExists() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";

        vm.startPrank(owner);
        assetFactory.createAsset(name, symbol, owner);

        vm.expectRevert(abi.encodeWithSelector(AssetFactory.AssetAlreadyExists.selector));
        assetFactory.createAsset(name, "TAST2", owner);
        vm.stopPrank();
    }

    function testAssetNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(AssetFactory.AssetNotFound.selector));
        assetFactory.getAssetDetails(address(0x789));
    }
}
