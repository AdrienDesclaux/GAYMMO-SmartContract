// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";


contract AssetToken is OwnableUpgradeable, ERC20Upgradeable, AccessControlUpgradeable {
    uint256 public limitSupply;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    error AlreadyInitialized();
    error InvalidNameOrSymbol();

    function initialize(string memory name_, string memory symbol_, uint256 _limitSupply, address owner_)
        external
        initializer
    {
        __AccessControl_init();
        if (bytes(name_).length == 0 || bytes(symbol_).length == 0) revert InvalidNameOrSymbol();
        __ERC20_init(name_, symbol_);
        __Ownable_init(owner_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, owner_);
        _grantRole(MINTER_ROLE, owner_);
        limitSupply = _limitSupply;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(msg.sender, amount);
    }
}
