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
import "forge-std/console.sol";

contract AssetManager is Initializable, OwnableUpgradeable {
    using AssetManagerMath for uint256;
    using SafeERC20 for IERC20;

    struct LastsInvestment {
        uint256 amount;
        uint256 timestamp;
        uint256 balance;
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
    event log_uint(uint256 value);

    error InvalidAssetAddress();
    error InvalidAssetTokenAddress();
    error InvalidFeedTokenAddress();
    error FeedTokenNotFound();
    error AssetNotFound();
    error InvalidAmount();
    error InvalidPrice();
    error LimitExceeded();
    error AlreadyInitialized();
    error NothingToClaim();
    error InvalidTimestamp();
    error InvalidTreasuryAddress();
    error TransfertFailed();

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
        availableSupply = _assetToken.limitSupply(); // Assuming limitSupply is set in AssetToken
        __Ownable_init(owner_);
    }

    function isETH(address token) internal pure returns (bool) {
    return token == address(0) || token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    //CHAINLINK PRICE FEEDS

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

    // GETTERS AND SETTERS

    function setRentUsdPerMonth(uint256 _rentUsdPerMonth) external onlyOwner {
        if (_rentUsdPerMonth == 0) revert InvalidPrice();
        rentUsdPerMonth = _rentUsdPerMonth;
    }

    function setUsdPricePerToken(uint256 _usdPricePerToken) external onlyOwner {
        if (_usdPricePerToken == 0) revert InvalidPrice();
        usdPricePerToken = _usdPricePerToken * 10 ** 18;
    }

    function getRentUsdPerMonth() external view returns (uint256) {
        return rentUsdPerMonth;
    }

    function getLimitSupply() external view returns (uint256) {
        return _assetToken.limitSupply();
    }

    function getAvailableSupply() external view returns (uint256) {
        return availableSupply;
    }

    function setAvailableSupply(uint256 _availableSupply) external onlyOwner {
        availableSupply = _availableSupply;
    }

    function getUsdPricePerToken() external view returns (uint256) {
        return usdPricePerToken;
    }

    function getLastsInvestment(address investor) external view returns (LastsInvestment[] memory) {
        return _lastInvestment[investor];
    }

    function getLastClaimed(address investor) external view returns (uint256) {
        return _lastClaimed[investor];
    }

    function getTreasuryAddress() external view returns (address) {
        return treasuryAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        if (_treasuryAddress == address(0)) revert InvalidTreasuryAddress();
        treasuryAddress = _treasuryAddress;
    }

    function calculateRentPrice() external view returns (uint256) {
        uint256 rent = this.getRentUsdPerMonth();
        if (rent <= 0) revert InvalidPrice();
        return AssetManagerMath.calculateSecondsRentPrice(rent);
    }

    function calculateAssetValue(uint256 quantity) external view returns (uint256) {
        if (quantity == 0) revert InvalidAmount();
        uint256 pricePerToken = this.getUsdPricePerToken();
        return AssetManagerMath.calculateAssetValue(pricePerToken, quantity);
    }

    /*function buyAssetTokenWithERC20(uint256 amount, address tokenAddress) external {
        if (amount == 0) revert InvalidAmount();
        if (address(priceFeeds[tokenAddress]) == address(0)) revert FeedTokenNotFound();
        if (availableSupply < amount) revert LimitExceeded();

        uint256 lastBalance = IERC20(address(_assetToken)).balanceOf(msg.sender);
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
            timestamp: block.timestamp,
            balance: lastBalance + amount
        }));

        emit Bought(msg.sender, amount, totalPrice);
    }
    */

    function buyAssetTokenWithETH(uint256 amount) external payable {
        if (amount == 0) revert InvalidAmount();
        if (availableSupply < amount) revert LimitExceeded();

        uint256 lastBalance = IERC20(address(_assetToken)).balanceOf(msg.sender);
        uint256 pricePerToken = this.getLastPriceToken(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        uint256 totalPrice = pricePerToken * amount;

        if (treasuryAddress != address(0) && treasuryAddress != address(this)) {
            (bool success, ) = payable(treasuryAddress).call{value: totalPrice}("");
            if (!success) {
                revert TransfertFailed();
            }
        }

        _assetToken.mint(msg.sender, amount);
        availableSupply -= amount;
        _lastClaimed[msg.sender] = block.timestamp;
        _lastInvestment[msg.sender].push(LastsInvestment({
            amount: amount,
            timestamp: block.timestamp,
            balance: lastBalance + amount
        }));

        emit Bought(msg.sender, amount, totalPrice);
    }

    /**
     * @notice Claim the rent for the user.
     * @param token The address of token for payment (ETH or Stablecoins).
     */
    function claimRent(address token) external {
        uint256 lastClaimed = _lastClaimed[msg.sender]; 
        if (lastClaimed == 0 || lastClaimed >= block.timestamp) {
            revert InvalidTimestamp();
        }  
        uint256 rentPrice = this.calculateRentPrice();
        uint256 rewards = 0;
        uint256 tokenPrice = this.getLastPriceToken(token);

        if (tokenPrice == 0) {
            revert InvalidPrice();
        }
        if (rentPrice == 0) {
            revert InvalidPrice();
        }
        if (availableSupply == 0) {
            revert LimitExceeded();
        }
        if( _lastInvestment[msg.sender].length == 0) {
            revert NothingToClaim();
        }
        if( _lastInvestment[msg.sender].length > 0 && _lastInvestment[msg.sender][0].balance == 0) {
            revert InvalidAmount();
        }

        if(_lastInvestment[msg.sender].length > 0) {
            for (uint256 i = 0; i < _lastInvestment[msg.sender].length; i++) {
                uint256 start = _lastInvestment[msg.sender][i].timestamp > lastClaimed ? _lastInvestment[msg.sender][i].timestamp : lastClaimed;
                uint256 end = (i + 1 < _lastInvestment[msg.sender].length) ? _lastInvestment[msg.sender][i + 1].timestamp : block.timestamp;

                if (start < end) {
                    uint256 differenceTime = end - start;
                    rewards += AssetManagerMath.calculateTotalClaimRent(
                        rentPrice,
                        differenceTime
                    ) * _lastInvestment[msg.sender][i].balance * 10 ** 18 / this.getLimitSupply();
                }
            }
        }
        
        rewards = (rewards * 10 ** 18) / tokenPrice;
        if (rewards == 0) {
            revert NothingToClaim();
        }
        _lastClaimed[msg.sender] = block.timestamp;
        if (rewards > 0) {
            if (isETH(token)) {
                payable(msg.sender).transfer(rewards);
            }
            else {
                IERC20(token).safeTransfer(this.treasuryAddress(), rewards);
            }
        }
    }
}
