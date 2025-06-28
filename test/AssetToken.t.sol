// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;


import {Test, console} from "forge-std/Test.sol";
import {AssetToken} from "../src/AssetToken.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AssetTokenTest is Test {
    AssetToken private assetToken;

    address private owner = address(0x123);
    address private user = address(0x456);

    function setUp() public {
        vm.startPrank(owner);
        assetToken = new AssetToken();
        assetToken.initialize("Test Token", "TTK", 1000 * 10 ** 18, owner);
        vm.stopPrank();
    }

    function testMint() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        assetToken.mint(user, 100 * 10 ** 18);
        vm.stopPrank();

        assertEq(assetToken.balanceOf(user), 100 * 10 ** 18);
    }

    function testBurn() public {
        vm.startPrank(owner);
        assetToken.mint(user, 100 * 10 ** 18);
        assetToken.grantRole(assetToken.ADMIN_ROLE(), user);
        vm.stopPrank();
        vm.startPrank(user);
        assetToken.burn(50 * 10 ** 18);
        vm.stopPrank();

        assertEq(assetToken.balanceOf(user), 50 * 10 ** 18);
    }

    function testMintWithInvalidRole() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, assetToken.MINTER_ROLE()));
        assetToken.mint(user, 100 * 10 ** 18);
        vm.stopPrank();
    }

    function testBurnWithInvalidRole() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, assetToken.ADMIN_ROLE()));
        assetToken.burn(50 * 10 ** 18);
        vm.stopPrank();
    }
}
