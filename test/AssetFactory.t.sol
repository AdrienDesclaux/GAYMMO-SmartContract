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
        // Déploiement des implémentations
        assetTokenImpl = new AssetToken();
        assetImpl = new Asset();
        assetManagerImpl = new AssetManager();

        // Création de la factory avec les implémentations
        assetFactory = new AssetFactory(
            address(assetImpl),
            address(assetTokenImpl),
            address(assetManagerImpl)
        );

        
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
}
