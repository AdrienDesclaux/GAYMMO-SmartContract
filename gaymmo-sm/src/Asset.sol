// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract Asset is ERC721URIStorage, Ownable, Pausable {
    
    uint256 public tokenCounter;

    constructor(string memory name_, string memory symbol_,  address _owner) ERC721(name_, symbol_) Ownable(msg.sender) Pausable() {
        tokenCounter = 0;
        transferOwnership(_owner);
    }
}
