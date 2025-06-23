// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract AssetToken is OwnableUpgradeable, ERC20Upgradeable {
    uint256 public limitSupply;
    string private _name;
    string private _symbol;
    bool private _initialized;

    error AlreadyInitialized();
    error InvalidNameOrSymbol();

    function initialize(string memory name_, string memory symbol_, uint256 initialSupply, address owner_)
        external
        initializer
    {
        if (bytes(name_).length == 0 || bytes(symbol_).length == 0) revert InvalidNameOrSymbol();
        __ERC20_init(name_, symbol_);
        __Ownable_init(owner_);
        limitSupply = initialSupply * 10;
        _mint(owner_, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
