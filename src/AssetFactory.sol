// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Asset} from "./Asset.sol";
import {AssetToken} from "./AssetToken.sol";
import {AssetManager} from "./AssetManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract AssetFactory {
    address public immutable assetImpl;
    address public immutable assetTokenImpl;
    address public immutable assetManagerImpl;

    address[] public _assets;
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

    constructor(address _assetImpl, address _assetTokenImpl, address _assetManagerImpl) {
        assetImpl = _assetImpl;
        assetTokenImpl = _assetTokenImpl;
        assetManagerImpl = _assetManagerImpl;
    }

    function createAsset(string memory name, string memory symbol, address _owner) external returns (address) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(symbol).length == 0) revert EmptySymbol();
        if (_existingAsset[nameHash]) revert AssetAlreadyExists();

        address assetClone = Clones.clone(assetImpl);
        address assetTokenClone = Clones.clone(assetTokenImpl);
        address assetManagerClone = Clones.clone(assetManagerImpl);

        Asset(assetClone).initialize(name, symbol, _owner);
        AssetToken(assetTokenClone).initialize(name, symbol, 1000000 * 10 ** 18, _owner);
        AssetManager(assetManagerClone).initialize(assetClone, assetTokenClone, 1, _owner);

        _assetDetails[assetClone] = Assets({
            assetAddress: assetClone,
            assetTokenAddress: assetTokenClone,
            assetManagerAddress: assetManagerClone,
            owner: _owner
        });
        _existingAsset[nameHash] = true;
        _isAssets[address(assetClone)] = true;
        _assets.push(assetClone);
        emit AssetCreated(address(assetClone), name, symbol);
        return assetClone;
    }

    function getAssetDetails(address assetAddress) external view returns (Assets memory) {
        if (!_isAssets[assetAddress]) revert AssetNotFound();
        return _assetDetails[assetAddress];
    }

    function getAssets() external view returns (address[] memory) {
        return _assets;
    }

    function isAsset(address assetAddress) external view returns (bool) {
        return _isAssets[assetAddress];
    }

    function getAssetCount() external view returns (uint256) {
        return _assets.length;
    }
}
