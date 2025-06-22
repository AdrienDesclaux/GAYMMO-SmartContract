// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { AssetFactory } from "../src/AssetFactory.sol";
import { AssetToken } from "../src/AssetToken.sol";
import { AssetManager } from "../src/AssetManager.sol";
import { Asset } from "../src/Asset.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract AssetFactoryTest is Test {
    AssetFactory private assetFactory;
    AssetToken private assetToken;
    AssetManager private assetManager;
    Asset private asset;

    address private owner = address(0x123);
    address private user = address(0x456);

    function setUp() public {
        assetFactory = new AssetFactory();
        assetToken = new AssetToken("Test Token", "TTK", 1000, owner);
        asset = new Asset("Test Asset", "TAST", owner);
        assetManager = new AssetManager(
            address(asset),
            address(assetToken),
            owner
        );
    }

    function testCreateAsset() public {
        string memory name = "Test Asset";
        string memory symbol = "TAST";

        vm.startPrank(owner);
            Asset createdAsset = assetFactory.createAsset(name, symbol, owner);
        vm.stopPrank();
        assertEq(createdAsset.name(), name);
        assertEq(createdAsset.symbol(), symbol);
        assertEq(assetFactory.getAssets().length, 1);
    }
}