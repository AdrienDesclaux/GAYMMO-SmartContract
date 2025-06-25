// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract Asset is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    uint256 public tokenCounter;
    bool public limitReached;

    error LimitReached();
    error AlreadyInitialized();
    error InvalidNameOrSymbol();

    function initialize(string memory name_, string memory symbol_, address owner_) external initializer {
        if (bytes(name_).length == 0 || bytes(symbol_).length == 0) revert InvalidNameOrSymbol();
        __ERC721_init(name_, symbol_);
        __Ownable_init(owner_);
        tokenCounter = 0;
        limitReached = false;
    }

    function mintAsset(address to, string memory tokenURI) external onlyOwner returns (uint256) {
        if (limitReached) revert LimitReached();
        uint256 newTokenId = tokenCounter;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        tokenCounter++;
        limitReached = true;
        return newTokenId;
    }
}
