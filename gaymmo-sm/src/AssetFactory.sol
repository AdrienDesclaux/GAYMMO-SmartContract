// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Asset } from "./Asset.sol";
import { AssetToken } from "./AssetToken.sol";
import { AssetManager } from "./AssetManager.sol";

contract AssetFactory {
    Asset[] public _assets;
    mapping(bytes32 => bool) private _existingAsset;
    mapping(address => bool) private _isAssets;
    mapping(address => Assets) private _assetDetails;
    struct Assets {
        address assetAddress;
        address assetTokenAddress;
        address assetManagerAddress;
        address owner;
    }

    event AssetCreated(address indexed assetAddress, string name, string symbol);
    error EmptyName();
    error EmptySymbol();
    error AssetAlreadyExists();
    error AssetNotFound();

    function createAsset(string memory name, string memory symbol, address _owner) external returns (Asset) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(symbol).length == 0) revert EmptySymbol();
        if (_existingAsset[nameHash]) revert AssetAlreadyExists();
        
        Asset asset = new Asset(name, symbol, _owner);
        AssetToken assetToken = new AssetToken(name, symbol, 1000000 * 10 ** 18, _owner);
        AssetManager assetManager = new AssetManager(address(asset), address(assetToken), _owner);
        _assetDetails[address(asset)] = Assets({
            assetAddress: address(asset),
            assetTokenAddress: address(assetToken),
            assetManagerAddress: address(assetManager),
            owner: _owner
        });
        _existingAsset[nameHash] = true;
        _isAssets[address(asset)] = true;
        _assets.push(asset);
        emit AssetCreated(address(asset), name, symbol);
        return asset;
    }

    function getAssetDetails(address assetAddress) external view returns (Assets memory) {
        if (!_isAssets[assetAddress]) revert AssetNotFound();
        return _assetDetails[assetAddress];
    }

    function getAssets() external view returns (Asset[] memory) {
        return _assets;
    }

    function isAsset(address assetAddress) external view returns (bool) {
        return _isAssets[assetAddress];
    }

    function getAssetCount() external view returns (uint256) {
        return _assets.length;
    }
}