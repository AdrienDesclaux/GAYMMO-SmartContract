/**
 * @author Yoyo77400
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Asset} from "./Asset.sol";
import {AssetToken} from "./AssetToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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
    error InvalidFeedTokenAddress();
    error FeedTokenNotFound();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();

    constructor(address assetAddress, address assetTokenAddress, uint256 _usdPricePerToken, address owner_)
        Ownable(msg.sender)
    {
        if (assetAddress == address(0)) revert InvalidAssetAddress();
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();
        if (_usdPricePerToken == 0) revert InvalidPrice();

        usdPricePerToken = _usdPricePerToken;
        _asset = Asset(assetAddress);
        _assetToken = AssetToken(assetTokenAddress);
        _transferOwnership(owner_);
    }

    function updateAssetToken(address assetTokenAddress) external onlyOwner {
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();
        _assetToken = AssetToken(assetTokenAddress);
        emit AssetTokenUpdated(assetTokenAddress);
    }

    /**
     * @notice Get the last price on a specify crypto for payement since a known price in FIAT, set before.
     * @param tokenAddress The cryptocurrency token address who want to have on payment.
     * @return price The last price of the token in USD, multiplied by 10^10 for precision with 18 decimals (only 8 returned by chainlink).
     */
    function getLastPrice(address tokenAddress) external view returns (int256) {
        if (address(priceFeeds[tokenAddress]) == address(0)) revert FeedTokenNotFound();
        (, int256 price,,,) = priceFeeds[tokenAddress].latestRoundData();
        return price * 10 ** 10;
    }

    /**
     * @notice Sets the price feed of this asset for specific cryptocyrency.
     * @param tokenAddress The cryptocurrency token address who want to have on payment.
     * @param priceFeedAddress the chainlink address of contract for Token/USD. If we want to use a pricePerToken in USD.
     */
    function setPriceFeed(address tokenAddress, address priceFeedAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidAssetTokenAddress();
        if (priceFeedAddress == address(0)) revert InvalidFeedTokenAddress();
        priceFeeds[tokenAddress] = AggregatorV3Interface(priceFeedAddress);
    }
}
