// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Asset } from "./Asset.sol";
import { AssetToken } from "./AssetToken.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract AssetManager is Ownable {

    mapping(address => AggregatorV3Interface) public priceFeeds;
    Asset private _asset;
    AssetToken private _assetToken;
    uint256 public usdPricePerToken;

    event AssetTokenUpdated(address indexed assetTokenAddress);
    event AssetOwnershipTransferred(address indexed newOwner);
    event Bought(address indexed buyer, uint256 amount, uint256 totalPrice);

    error InvalidAssetAddress();
    error InvalidAssetTokenAddress();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();

    constructor(address assetAddress, address assetTokenAddress,uint256 _usdPricePerToken, address owner_) Ownable(msg.sender) {
        if (assetAddress == address(0)) revert InvalidAssetAddress();
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();
        if (_usdPricePerToken == 0) revert InvalidPrice();

        usdPricePerToken = _usdPricePerToken;
        _asset = Asset(assetAddress);
        _assetToken = AssetToken(assetTokenAddress);
        _transferOwnership(owner_);
    }
}
