// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Asset } from "./Asset.sol";
import { AssetToken } from "./AssetToken.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract AssetManager is Ownable {

    Asset private _asset;
    AssetToken private _assetToken;

    event AssetTokenUpdated(address indexed assetTokenAddress);
    event AssetOwnershipTransferred(address indexed newOwner);
    event Bought(address indexed buyer, uint256 amount, uint256 totalPrice);

    error InvalidAssetAddress();
    error InvalidAssetTokenAddress();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();

    constructor(address assetAddress, address assetTokenAddress, address owner_) Ownable(msg.sender) {
        if (assetAddress == address(0)) revert InvalidAssetAddress();
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();

        _asset = Asset(assetAddress);
        _assetToken = AssetToken(assetTokenAddress);
        _transferOwnership(owner_);
    }
}
