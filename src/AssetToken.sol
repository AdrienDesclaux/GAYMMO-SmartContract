// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AssetToken is ERC20, Ownable {
    uint256 public limitSupply;
    bool private _initialized;
    string private _name;
    string private _symbol;

    error AlreadyInitialized();
    error InvalidNameOrSymbol();


    modifier initializer() {
        if (_initialized) revert AlreadyInitialized();
        _;
        _initialized = true;
    }

    constructor() ERC20("","") Ownable(msg.sender) {
       
    }

    function initialize(string memory name_, string memory symbol_, uint256 initialSupply, address owner_) external {
        if (_initialized) revert AlreadyInitialized();
        if (bytes(name_).length == 0 || bytes(symbol_).length == 0) revert InvalidNameOrSymbol();
        _name = name_;
        _symbol = symbol_;
        limitSupply = initialSupply * 10;
        transferOwnership(owner_);
        _mint(owner_, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
