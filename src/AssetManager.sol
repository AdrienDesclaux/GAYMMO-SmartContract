/**
 * @author Yoyo77400
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Asset} from "./Asset.sol";
import {AssetToken} from "./AssetToken.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { AssetManagerMath } from "../utils/assetManagerMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AssetManager is Initializable, OwnableUpgradeable {
    using AssetManagerMath for uint256;
    using SafeERC20 for IERC20;

    struct LastsInvestment {
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => AggregatorV3Interface) public priceFeeds;
    address public treasuryAddress;
    Asset private _asset;
    AssetToken private _assetToken;
    uint256 public usdPricePerToken;
    bool private _initialized;
    uint256 private rentUsdPerMonth;
    uint256 private availableSupply;
    mapping(address => uint256) private _lastClaimed;
    mapping(address => LastsInvestment[]) private _lastInvestment;


    event AssetTokenUpdated(address indexed assetTokenAddress);
    event AssetOwnershipTransferred(address indexed newOwner);
    event Bought(address indexed buyer, uint256 amount, uint256 totalPrice);
    event PriceFeedSet(address indexed tokenAddress, address indexed priceFeedAddress);

    error InvalidAssetAddress();
    error InvalidAssetTokenAddress();
    error InvalidFeedTokenAddress();
    error FeedTokenNotFound();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();
    error AlreadyInitialized();

    function initialize(address assetAddress, address assetTokenAddress, uint256 _usdPricePerToken, address owner_)
        external
        initializer
    {
        if (assetAddress == address(0)) revert InvalidAssetAddress();
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();
        if (_usdPricePerToken == 0) revert InvalidPrice();

        usdPricePerToken = _usdPricePerToken * 10 ** 18;
        _asset = Asset(assetAddress);
        _assetToken = AssetToken(assetTokenAddress);
        availableSupply = _assetToken.totalSupply(); // Assuming limitSupply is set in AssetToken
        __Ownable_init(owner_);
    }

    function updateAssetToken(address assetTokenAddress) external onlyOwner {
        if (assetTokenAddress == address(0)) revert InvalidAssetTokenAddress();
        _assetToken = AssetToken(assetTokenAddress);
        emit AssetTokenUpdated(assetTokenAddress);
    }

    /**
     * @notice Get the last price on a specify crypto for payement since a known price in FIAT, set before.
     * @param tokenAddress The cryptocurrency token address who want to have on payment.
     * @return price The last price of the token on a cryptocurrency, based on USD estimated price !.
     */
    function getLastPriceToken(address tokenAddress) external view returns (uint256) {
        if (address(priceFeeds[tokenAddress]) == address(0)) revert FeedTokenNotFound();
        (, int256 price,,,) = priceFeeds[tokenAddress].latestRoundData();
        if (price <= 0) revert InvalidPrice();
        uint256 feedPrice = uint256(price) * 10 ** 10;
        uint256 assetTokenPrice = (usdPricePerToken * 10 ** 18) / feedPrice;
        return assetTokenPrice;
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
        emit PriceFeedSet(tokenAddress, priceFeedAddress);
    }

    function setRentUsdPerMonth(uint256 _rentUsdPerMonth) external onlyOwner {
        if (_rentUsdPerMonth == 0) revert InvalidPrice();
        rentUsdPerMonth = _rentUsdPerMonth * 10 ** 18;
    }

    function getRentUsdPerMonth() external view returns (uint256) {
        return rentUsdPerMonth;
    }

    function getTotalSupply() external view returns (uint256) {
        return _assetToken.totalSupply();
    }

    function getAvailableSupply() external view returns (uint256) {
        return availableSupply;
    }

    function setAvailableSupply(uint256 _availableSupply) external onlyOwner {
        if (_availableSupply == 0) revert InvalidAmount();
        availableSupply = _availableSupply;
    }

    function getUsdPricePerToken() external view returns (uint256) {
        return usdPricePerToken;
    }

    function getLastsInvestment(address investor) external view returns (LastsInvestment[] memory) {
        return _lastInvestment[investor];
    }

    function calculateRentPrice() external view returns (uint256) {
        uint256 rent = this.getRentUsdPerMonth(); // Ensure the rentUsdPerMonth is set before calculation
        return AssetManagerMath.calculateSecondsRentPrice(rent);
    }

    function calculateAssetValue(uint256 quantity) external view returns (uint256) {
        if (quantity == 0) revert InvalidAmount();
        uint256 pricePerToken = this.getUsdPricePerToken();
        return AssetManagerMath.calculateAssetValue(pricePerToken, quantity);
    }

    function buyAssetTokenWithERC20(uint256 amount, address tokenAddress) external {
        if (amount == 0) revert InvalidAmount();
        if (address(priceFeeds[tokenAddress]) == address(0)) revert FeedTokenNotFound();
        if (availableSupply < amount) revert LimitExceeded();

        uint256 pricePerToken = this.getLastPriceToken(tokenAddress);
        if (pricePerToken == 0) revert InvalidPrice();
        uint256 totalPrice = pricePerToken * amount;

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            totalPrice
        );
        
        if (treasuryAddress != address(0) && treasuryAddress != address(this)) {
            IERC20(tokenAddress).safeTransfer(treasuryAddress, totalPrice);
        }

        _assetToken.mint(msg.sender, amount);
        availableSupply -= amount;
        _lastInvestment[msg.sender].push(LastsInvestment({
            amount: amount,
            timestamp: block.timestamp
        }));

        emit Bought(msg.sender, amount, totalPrice);
    }

    function buyAssetTokenWithETH(uint256 amount) external payable {
        if (amount == 0) revert InvalidAmount();
        if (availableSupply < amount) revert LimitExceeded();

        uint256 pricePerToken = this.getLastPriceToken(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        if (pricePerToken == 0) revert InvalidPrice();
        uint256 totalPrice = pricePerToken * amount;

        if (treasuryAddress != address(0) && treasuryAddress != address(this)) {
            payable(treasuryAddress).transfer(totalPrice);
        }

        _assetToken.mint(msg.sender, amount);
        availableSupply -= amount;
        _lastInvestment[msg.sender].push(LastsInvestment({
            amount: amount,
            timestamp: block.timestamp
        }));

        emit Bought(msg.sender, amount, totalPrice);
    }
}
