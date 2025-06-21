// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract AssetToken is ERC20, Ownable {
    
    uint256 public limitSupply;

    constructor(string memory name_, string memory symbol_, uint256 initialSupply, address owner_) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(owner_, initialSupply);
        limitSupply = initialSupply * 10;
        _transferOwnership(owner_);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}