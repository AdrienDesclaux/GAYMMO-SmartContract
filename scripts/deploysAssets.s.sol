// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/Asset.sol";
import "../src/AssetManager.sol";
import "../src/AssetFactory.sol";
import "../src/AssetToken.sol";

contract DeployAssets is Script {
    function run() external {
        vm.startBroadcast();

        Asset assetImpl = new Asset();
        AssetManager assetManagerImpl = new AssetManager();
        AssetToken assetTokenImpl = new AssetToken();

        AssetFactory assetFactory = new AssetFactory(address(assetImpl), address(assetTokenImpl), address(assetManagerImpl));

        vm.stopBroadcast();
        console.log("Asset deployed at:", address(assetImpl));
        console.log("AssetManager deployed at:", address(assetManagerImpl));
        console.log("AssetFactory deployed at:", address(assetFactory));
        console.log("AssetToken deployed at:", address(assetTokenImpl));
    }
}