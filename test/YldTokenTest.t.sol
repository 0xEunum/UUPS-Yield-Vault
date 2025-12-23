// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {YldToken} from "src/YldToken.sol";

contract YldTokenTest is Test {
    YldToken token;

    address owner = makeAddr("owner");
    address user = makeAddr("user");

    function setUp() public {
        vm.prank(owner);
        token = new YldToken();
    }

    function testTokenAuthentication() public {
        assertEq(owner, token.owner());

        vm.prank(user);
        vm.expectRevert();
        token.setProxy(address(1));

        vm.prank(owner);
        vm.expectRevert();
        token.mint(user, 1e18);

        vm.prank(owner);
        vm.expectRevert();
        token.burn(user, 1e18);
    }

    function testProxyAddress() public {
        assertEq(address(0), token.proxy());

        vm.prank(owner);
        vm.expectRevert(YldToken.YldToken__ZeroAddress.selector);
        token.setProxy(address(0));

        vm.prank(owner);
        token.setProxy(address(1));

        assertEq(token.proxy(), address(1));
    }

    function testOnlyProxyCanMintAndBurn() public {
        vm.prank(owner);
        vm.expectRevert(YldToken.YldToken__ProxyNotSet.selector);
        token.mint(owner, 1e18);

        vm.prank(owner);
        token.setProxy(address(1));

        vm.prank(owner);
        vm.expectRevert(YldToken.YldToken__Unauthoraized.selector);
        token.mint(owner, 1e18);

        vm.prank(owner);
        vm.expectRevert(YldToken.YldToken__Unauthoraized.selector);
        token.burn(owner, 1e18);

        uint256 beforeBalance = token.balanceOf(owner);
        assertEq(0, beforeBalance);

        vm.prank(address(1));
        token.mint(owner, 1e18);

        uint256 afterBalance = token.balanceOf(owner);

        assertEq(1e18, afterBalance);

        vm.prank(address(1));
        token.burn(owner, 1e18);

        uint256 tokenAfterBurn = token.balanceOf(owner);

        assertEq(0, tokenAfterBurn);
    }
}
