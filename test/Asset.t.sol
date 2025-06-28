// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Asset} from "../src/Asset.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";


contract AssetTest is Test {
    Asset private asset;

    address private owner = address(0x123);
    address private user = address(0x456);

    function setUp() public {
        vm.startPrank(owner);
        asset = new Asset();
        asset.initialize("Test Asset", "TAST", owner);
        vm.stopPrank();
    }

    function testMintAsset() public {
        vm.startPrank(owner);
        uint256 tokenId = asset.mintAsset(user, "https://example.com/metadata.json");
        vm.stopPrank();

        assertEq(asset.ownerOf(tokenId), user);
        assertEq(asset.tokenURI(tokenId), "https://example.com/metadata.json");
    }

    function testMintAssetLimitReached() public {
        vm.startPrank(owner);
        asset.mintAsset(user, "https://example.com/metadata.json");
        vm.expectRevert(Asset.LimitReached.selector);
        asset.mintAsset(user, "https://example.com/metadata2.json");
        vm.stopPrank();
    }

    function testMintAssetWithInvalidNameOrSymbol() public {
        vm.startPrank(owner);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        asset.initialize("", "TAST", owner);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        asset.initialize("Test Asset", "", owner);
        vm.stopPrank();
    }
}