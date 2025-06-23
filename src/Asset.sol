// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract Asset is ERC721URIStorage, Ownable, Pausable {
    uint256 public tokenCounter;
    bool public limitReached;
    bool private _initialized;
    string private _name;
    string private _symbol;

    error LimitReached();
    error AlreadyInitialized();
    error InvalidNameOrSymbol();

    modifier initializer() {
        if (_initialized) revert AlreadyInitialized();
        _;
        _initialized = true;
    }

    constructor() ERC721("", "") Ownable(msg.sender) Pausable(){
    
    }

    function initialize(string memory name_, string memory symbol_, address _owner) external initializer {
        if (bytes(name_).length == 0 || bytes(symbol_).length == 0) revert InvalidNameOrSymbol();
        _name = name_;
        _symbol = symbol_;
        transferOwnership(_owner);
    }

    function mintAsset(address to, string memory tokenURI) external onlyOwner whenNotPaused returns (uint256) {
        if (limitReached) revert LimitReached();
        uint256 newTokenId = tokenCounter;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        tokenCounter++;
        limitReached = true;
        return newTokenId;
    }
}
